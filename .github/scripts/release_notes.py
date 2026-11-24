"""Write release notes for the exact numeric tag checked out by Actions."""
import re
import subprocess
import sys


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def notes(tag):
    version_pattern = r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    if not re.fullmatch(version_pattern, tag):
        raise ValueError(f"Expected a stable version tag: {tag}")
    ref = f"refs/tags/{tag}"
    if git("rev-parse", f"{ref}^{{commit}}") != git("rev-parse", "HEAD"):
        raise ValueError("The tag and checked-out commit differ")
    version = tuple(map(int, tag.split(".")))
    previous = []
    for candidate in git("tag", "--merged", ref).splitlines():
        if re.fullmatch(version_pattern, candidate):
            parts = tuple(map(int, candidate.split(".")))
            if parts < version:
                previous.append((parts, candidate))
    revision = f"refs/tags/{max(previous)[1]}..{ref}" if previous else ref
    groups = {}
    for message in git("log", "--no-merges", "-z", "--format=%B", revision).split("\0"):
        if not message.strip():
            continue
        subject = message.splitlines()[0]
        match = re.match(r"^(\w+)(?:\([^)]+\))?(!)?: ", subject)
        kind = match[1] if match else ""
        heading = {"fix": "Fixes", "feat": "Features", "perf": "Performance"}.get(kind, "Other changes")
        breaking = re.search(r"^BREAKING[ -]CHANGE: (.+)$", message, re.M)
        if breaking or (match and match[2]):
            heading = "Breaking changes"
        line = subject + (f" — {breaking[1]}" if breaking else "")
        groups.setdefault(heading, []).append(line)
    for heading in ("Breaking changes", "Features", "Fixes", "Performance", "Other changes"):
        if heading in groups:
            print(f"## {heading}\n")
            for line in groups[heading]:
                print(f"- {line}")
            print()
    if not groups:
        print(f"Release {tag}.")


if __name__ == "__main__":
    notes(sys.argv[1])
