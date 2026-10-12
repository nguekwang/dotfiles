#!/usr/bin/env python3
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def main():
    try:
        data = json.loads(sys.stdin.read(1024 * 1024))
        value = data.get("tool_input", {}).get("file_path", "")
        if not value:
            return 0
        path = pathlib.Path(value)
        if not path.is_absolute():
            cwd = pathlib.Path(data.get("cwd") or ROOT)
            path = cwd / path
        rel = path.resolve().relative_to(ROOT)
    except (ValueError, TypeError, AttributeError, OSError):
        return 0
    if not (rel.parts and rel.parts[0] in ("home", "etc")) and rel.as_posix() not in (
        "setup.sh", "test/unwired-files.txt"
    ):
        return 0
    try:
        result = subprocess.run(
            ["sh", str(ROOT / "test/deployment-test.sh")], cwd=ROOT,
            capture_output=True, text=True, timeout=60,
        )
        if result.returncode == 0:
            return 0
        lines = [line for line in (result.stdout + result.stderr).splitlines()
                 if line and not line.startswith("ok -")][:10]
        message = "\n".join(lines) + "\nWire the source with link user or link sudo, or add a justified test/unwired-files.txt exemption."
    except (OSError, subprocess.SubprocessError):
        message = "Deployment check could not complete; run sh test/all explicitly."
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "[hook: check-dotfile-wiring] " + message,
    }}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
