import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


class Fail(Exception):
    pass


def _paint(code, text):
    if sys.stdout.isatty():
        return f"\033[{code}m{text}\033[0m"
    return text


def step(msg):
    print(_paint("36", f"==> {msg}"))


def ok(msg):
    print(_paint("32", f"    {msg}"))


def skip(msg):
    print(_paint("90", f"    {msg}"))


def run(fn):
    try:
        fn()
    except Fail as exc:
        print(f"error: {exc}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(130)
