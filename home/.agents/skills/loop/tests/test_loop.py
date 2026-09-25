import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "loop.py"
spec = importlib.util.spec_from_file_location("loop", SCRIPT)
loop = importlib.util.module_from_spec(spec)
spec.loader.exec_module(loop)


class ParsingTests(unittest.TestCase):
    def test_leading_decimal_and_case(self):
        parsed = loop.parse_request("1.5H check the build")
        self.assertEqual(parsed["interval_ms"], 5_400_000)
        self.assertEqual(parsed["prompt"], "check the build")

    def test_preserves_prompt_whitespace_and_skill_mention(self):
        prompt = "$simplify src/\nKeep  these  spaces."
        self.assertEqual(loop.parse_request("5m\t" + prompt)["prompt"], prompt)

    def test_trailing_units(self):
        for suffix in ["2h", "2hours", "2 hours"]:
            with self.subTest(suffix=suffix):
                parsed = loop.parse_request("check the build every " + suffix)
                self.assertEqual(parsed["interval_ms"], 7_200_000)
                self.assertEqual(parsed["prompt"], "check the build")

    def test_leading_interval_has_priority(self):
        parsed = loop.parse_request("5m check every 20m")
        self.assertEqual(parsed["interval_ms"], 300_000)
        self.assertEqual(parsed["prompt"], "check every 20m")

    def test_default_and_minimum(self):
        self.assertEqual(loop.parse_request("check the build")["interval_ms"], 600_000)
        parsed = loop.parse_request("0.5s check")
        self.assertEqual(parsed["interval_ms"], 10_000)
        self.assertTrue(parsed["clamped"])

    def test_invalid_or_missing_interval_input(self):
        for text in ["5m", "3w check", "-5m check", "9" * 400 + "h check"]:
            with self.subTest(text=text[:20]), self.assertRaises(ValueError):
                loop.parse_request(text)

    def test_management(self):
        self.assertEqual(loop.parse_request(""), {"action": "help"})
        self.assertEqual(loop.parse_request("list"), {"action": "list"})
        self.assertEqual(loop.parse_request("stop"), {"action": "stop", "id": None})
        self.assertEqual(loop.parse_request("stop loop-2"), {"action": "stop", "id": "loop-2"})


class ScheduleTests(unittest.TestCase):
    def setUp(self):
        self.state = {}
        self.start = 1_000_000

    def call(self, action, elapsed=0, **kwargs):
        return loop.dispatch(self.state, action, self.start + elapsed, **kwargs)

    def add(self, text="10s check", elapsed=0):
        return self.call("request", elapsed, request=text)["job"]["id"]

    def test_first_run_immediate_and_counted(self):
        job_id = self.add()
        first = self.call("next")
        self.assertEqual(first["action"], "run")
        self.assertEqual(first["job"]["runs_started"], 1)
        self.call("done", 1000, job_id=job_id)
        self.assertEqual(self.call("next", 1000), {"action": "wait", "duration_ms": 9000})
        self.assertEqual(self.call("next", 10_000)["job"]["runs_started"], 2)
        self.assertEqual(self.state["jobs"][0]["runs_completed"], 1)

    def test_early_wake_does_not_run_the_task(self):
        job_id = self.add("10m check")
        self.call("next")
        self.call("done", 1000, job_id=job_id)
        self.assertEqual(self.call("next", 5000), {"action": "wait", "duration_ms": 60_000})
        self.assertEqual(self.call("next", 599_000), {"action": "wait", "duration_ms": 1000})
        self.assertEqual(self.state["jobs"][0]["runs_started"], 1)

    def test_slow_run_skips_missed_ticks(self):
        job_id = self.add()
        self.call("next")
        self.call("done", 25_000, job_id=job_id)
        self.assertEqual(self.call("next", 25_000), {"action": "wait", "duration_ms": 5000})
        self.assertEqual(self.call("next", 30_000)["action"], "run")

    def test_exact_boundary_advances_to_the_future(self):
        job_id = self.add()
        self.call("next")
        self.call("done", 10_000, job_id=job_id)
        self.assertEqual(self.call("next", 10_000), {"action": "wait", "duration_ms": 10_000})

    def test_no_overlapping_runs_even_for_different_jobs(self):
        first = self.add()
        second = self.add("20s another task")
        self.assertEqual(self.call("next")["job"]["id"], first)
        self.assertEqual(self.call("next", 1000), {"action": "running", "ids": [first]})
        self.call("done", 1000, job_id=first)
        self.assertEqual(self.call("next", 1000)["job"]["id"], second)

    def test_stop_running_job_cannot_be_undone_by_done(self):
        job_id = self.add()
        self.call("next")
        self.call("stop", 1000, job_id=job_id)
        self.call("done", 2000, job_id=job_id)
        self.assertEqual(self.state["jobs"][0]["status"], "stopped")
        self.assertEqual(self.call("next", 50_000), {"action": "idle"})

    def test_stop_one_and_stop_all(self):
        first = self.add()
        second = self.add()
        self.assertEqual(self.call("request", request="stop " + first)["ids"], [first])
        self.assertEqual(self.call("request", request="stop missing")["ids"], [])
        self.assertEqual(self.call("request", request="stop")["ids"], [second])
        self.assertEqual(self.call("next"), {"action": "idle"})

    def test_expiry_prevents_late_runs(self):
        self.add()
        self.assertEqual(self.call("next", loop.MAX_AGE_MS), {"action": "idle"})
        self.assertEqual(self.state["jobs"][0]["status"], "expired")

    def test_long_interval_still_expires(self):
        job_id = self.add("8d check")
        self.call("next")
        self.call("done", 1, job_id=job_id)
        self.assertEqual(
            self.call("next", loop.MAX_AGE_MS - 5),
            {"action": "wait", "duration_ms": 5},
        )
        self.assertEqual(self.call("next", loop.MAX_AGE_MS), {"action": "idle"})

    def test_list_retains_distinct_job_ids_and_counts(self):
        first = self.add()
        self.call("next")
        self.call("done", 1, job_id=first)
        self.call("stop", job_id=first)
        second = self.add()
        jobs = self.call("list")["jobs"]
        self.assertEqual([job["id"] for job in jobs], [first, second])
        self.assertNotEqual(first, second)
        self.assertEqual(jobs[0]["runs_completed"], 1)

    def test_unknown_completion_fails(self):
        with self.assertRaises(ValueError):
            self.call("done", job_id="missing")

    def test_requested_run_limit_includes_first_run(self):
        job = self.call("request", request="10s check", max_runs=2)["job"]
        self.call("next")
        self.call("done", 1000, job_id=job["id"])
        self.call("next", 10_000)
        self.call("done", 11_000, job_id=job["id"])
        self.assertEqual(job["status"], "completed")
        self.assertEqual(job["runs_completed"], 2)
        self.assertEqual(self.call("next", 20_000), {"action": "idle"})

    def test_requested_duration_limits_wait(self):
        job = self.call("request", request="5m check", duration_ms=15_000)["job"]
        self.call("next")
        self.call("done", 1000, job_id=job["id"])
        self.assertEqual(self.call("next", 1000), {"action": "wait", "duration_ms": 14_000})
        self.assertEqual(self.call("next", 15_000), {"action": "idle"})
        self.assertEqual(job["status"], "expired")

    def test_completion_after_deadline_is_counted_without_rescheduling(self):
        job = self.call("request", request="10s check", duration_ms=5000)["job"]
        self.call("next")
        self.call("done", 6000, job_id=job["id"])
        self.assertEqual(job["runs_completed"], 1)
        self.assertEqual(job["status"], "expired")
        self.assertEqual(self.call("next", 6000), {"action": "idle"})

    def test_deadline_does_not_overlap_an_inflight_action(self):
        first = self.call("request", request="10s check", duration_ms=5000)["job"]
        second = self.add()
        self.call("next")
        self.assertEqual(self.call("next", 6000), {"action": "running", "ids": [first["id"]]})
        self.call("done", 6000, job_id=first["id"])
        self.assertEqual(self.call("next", 6000)["job"]["id"], second)

    def test_limits_must_be_positive(self):
        for limits in [{"max_runs": 0}, {"duration_ms": -1}]:
            with self.subTest(limits=limits), self.assertRaises(ValueError):
                self.call("request", request="10s check", **limits)


class CliTests(unittest.TestCase):
    def test_requested_limits_through_cli(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / "state.json"

            def run(*arguments):
                result = subprocess.run(
                    [sys.executable, str(SCRIPT), "--state", str(state), *arguments],
                    text=True, capture_output=True, check=True,
                )
                return json.loads(result.stdout)

            job = run(
                "request", "10s check", "--max-runs", "1", "--duration-ms", "60000",
            )["job"]
            self.assertEqual(job["expires_at_ms"] - job["created_at_ms"], 60000)
            run("next")
            self.assertEqual(run("done", job["id"])["job"]["status"], "completed")
            self.assertEqual(run("next")["action"], "idle")

    def test_persistence_and_prompt_is_data(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            state = root / "state.json"
            marker = root / "must-not-exist"
            text = f"10s $(touch {marker})"

            def run(*arguments):
                result = subprocess.run(
                    [sys.executable, str(SCRIPT), "--state", str(state), *arguments],
                    text=True, capture_output=True, check=True,
                )
                return json.loads(result.stdout)

            created = run("request", text)
            self.assertEqual(created["job"]["prompt"], text[4:])
            self.assertFalse(marker.exists())
            self.assertEqual(run("next")["action"], "run")
            self.assertEqual(run("stop")["ids"], [created["job"]["id"]])
            self.assertEqual(run("next")["action"], "idle")
            self.assertEqual(run("list")["jobs"][0]["status"], "stopped")
            self.assertEqual(state.stat().st_mode & 0o777, 0o600)

    def test_invalid_request_does_not_create_state(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / "state.json"
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--state", str(state), "request", "5m"],
                text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 2)
            self.assertFalse(state.exists())

    def test_missing_thread_id_requires_explicit_state(self):
        environment = dict(os.environ)
        environment.pop("CODEX_THREAD_ID", None)
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "list"],
            env=environment, text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("--state", result.stderr)


if __name__ == "__main__":
    unittest.main()
