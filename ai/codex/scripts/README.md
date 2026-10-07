# Codex Git context

The footer keeps its existing model, context, full-directory, and change-count
fields. Its Git label uses Starship's detector: `w:<worktree>` takes precedence;
ordinary checkouts show `b:<branch>`.

`git-context.py` supplies the data. The Stow entrypoint
`home/.codex/git-context.py` links here. At a Brazil workspace parent, counts
sum committed branch changes across Git packages under `src/`; inside a package,
counts cover that repository.

`native-status.patch` contains the native Codex change and its tests. It applies
to OpenAI's `rust-v0.160.0`, commit
`a956835d020762cb2b570053af06f643a11c0ecc`. The Toolbox launcher and its Amazon
authentication remain in use through `CODEX_NATIVE_BINARY`.

To rebuild and install on this Linux host (Python 3.11+, Git, and Rustup required):

```sh
python3 ai/codex/scripts/build-native.py
```

The build uses Rust 1.95.0 and a normal source checkout under
`~/.cache/codex-status/source`. It creates no task worktrees. Matching runtime
helpers come from Toolbox Codex `0.160.0.614`; the installed executable lives in
`~/.local/lib/codex-status/`. Updating Codex requires updating the pinned source
and patch.

Run the helper tests with:

```sh
python3 -B -m unittest discover -s ai/codex/scripts -p test_git_context.py
```
