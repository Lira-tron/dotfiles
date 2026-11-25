"""Narrow literal-data exemptions for a conservative, advisory shell hook.

This is deliberately not a shell interpreter. Compound commands, substitutions,
unknown wrappers and arbitrary Python retain the hook's conservative checks.
"""

import ast
import re
import shlex
from pathlib import PurePosixPath


def literal_path(node):
    return (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
            and node.func.id == "Path" and not node.keywords and len(node.args) == 1
            and isinstance(node.args[0], ast.Constant) and isinstance(node.args[0].value, str))


def document_statement(node):
    """Recognize only Path('literal').write_text('literal') document writes."""
    if not isinstance(node, ast.Expr) or not isinstance(node.value, ast.Call):
        return False
    call = node.value
    if not isinstance(call.func, ast.Attribute) or call.func.attr != "write_text":
        return False
    return (literal_path(call.func.value) and not call.keywords and len(call.args) == 1
            and isinstance(call.args[0], ast.Constant) and isinstance(call.args[0].value, str))


def inert_python(source):
    tree = ast.parse(source)
    if not tree.body:
        return False
    first = tree.body[0]
    if not isinstance(first, ast.ImportFrom) or first.module != "pathlib" or first.level != 0:
        return False
    if [(alias.name, alias.asname) for alias in first.names] != [("Path", None)]:
        return False
    return bool(tree.body[1:]) and all(document_statement(node) for node in tree.body[1:])


def simple_words(source):
    """Accept a single simple command, with no executable shell expansion."""
    if any(char in source for char in ";|&$`(){}\n"):
        return []
    return shlex.split(source)


def inert_document(source):
    """Accept only a quoted, terminated here-document on one literal command."""
    match = re.fullmatch(r"([^\n]*?)\s*<<(['\"])([A-Za-z_]\w*)\2\s*\n(.*?)\n\3\n?", source, re.S)
    if not match:
        return False
    header, _, delimiter, body = match.groups()
    if "<" in header or delimiter in body.splitlines():
        return False
    words = simple_words(header)
    if not words:
        return False
    executable = PurePosixPath(words[0]).name
    if executable == "cat":
        return True
    if not re.fullmatch(r"python(?:\d+(?:\.\d+)?)?", executable) or words[1:] != ["-"]:
        return False
    return inert_python(body)


def inert_data_command(source):
    """Exempt verified data arguments, not arbitrary commands containing quotes."""
    try:
        if "\n" in source:
            return inert_document(source)
        words = simple_words(source)
        if not words:
            return False
        executable = PurePosixPath(words[0]).name
        if executable == "rg":
            return not any(word.startswith("--pre") for word in words)
        if executable == "claude":
            return not any(word.startswith(("--settings", "--mcp-config")) for word in words)
        return executable in {"grep", "cat", "head", "tail", "echo", "printf", "rm"}
    except (ValueError, SyntaxError):
        return False
