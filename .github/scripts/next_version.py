"""Select the next stable Git tag from the Angular commits reachable from HEAD."""
import re
import subprocess

VERSION = r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)"
HEADER = re.compile(r"^(?P<type>[a-z]+)(?:\([^)]+\))?(?P<breaking>!)?: .+")


def git(*args):
    return subprocess.check_output(["git", *args], text=True)


def version_tuple(tag):
    return tuple(map(int, tag.split(".")))


def next_version():
    tags = [tag for tag in git("tag", "--merged", "HEAD").splitlines()
            if re.fullmatch(VERSION, tag)]
    previous = max(tags, key=version_tuple) if tags else None
    revision = f"{previous}..HEAD" if previous else "HEAD"
    level = 0
    override = None
    for message in git("log", "-z", "--format=%B", revision).split("\0"):
        if not message.strip():
            continue
        trailers = subprocess.check_output(
            ["git", "interpret-trailers", "--parse"], input=message, text=True)
        explicit = re.search(rf"^Release-As: ({VERSION})$", trailers, re.M)
        if explicit and override is None:
            override = explicit[1]
        header = HEADER.match(message)
        if not header:
            continue
        if header["breaking"] or re.search(r"^BREAKING[ -]CHANGE: \S", message, re.M):
            level = 3
        elif header["type"] == "feat":
            level = max(level, 2)
        elif header["type"] in {"fix", "perf", "revert"}:
            level = max(level, 1)
    current = version_tuple(previous) if previous else (0, 0, 0)
    if override:
        if version_tuple(override) <= current:
            raise ValueError(f"Release-As {override} must exceed {previous}")
        return override
    if not level:
        return ""
    parts = list(current)
    index = 3 - level
    parts[index] += 1
    parts[index + 1:] = [0] * (2 - index)
    return ".".join(map(str, parts))


if __name__ == "__main__":
    print(next_version())
