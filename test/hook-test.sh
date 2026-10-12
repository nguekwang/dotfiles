. "$(dirname "$0")/base-test.sh"
python3 - "$ROOT" <<'PY'
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

root = pathlib.Path(sys.argv[1])
with tempfile.TemporaryDirectory(prefix="dotfile-hook-") as tmp:
    fixture = pathlib.Path(tmp)
    for name in ("home", "etc", "test"):
        shutil.copytree(root / name, fixture / name)
    shutil.copyfile(root / "setup.sh", fixture / "setup.sh")
    hooks = fixture / ".claude/hooks"
    hooks.mkdir(parents=True)
    hook = hooks / "check-dotfile-wiring.py"
    shutil.copyfile(root / ".claude/hooks/check-dotfile-wiring.py", hook)
    target = fixture / "home/unwired-fixture.conf"
    target.write_text("fixture")
    def run(path):
        payload = {"cwd": str(fixture), "tool_input": {"file_path": str(path)}}
        return subprocess.run([sys.executable, str(hook)], input=json.dumps(payload),
                              text=True, capture_output=True, check=True)
    output = json.loads(run(target).stdout)
    assert "home/unwired-fixture.conf" in output["hookSpecificOutput"]["additionalContext"]
    assert run(fixture / "README.md").stdout == ""
    assert run(pathlib.Path(tmp).parent / "outside.conf").stdout == ""
    target.unlink()
    assert run(fixture / "setup.sh").stdout == ""
print("ok - wiring hook reports failures, ignores unrelated paths and accepts a valid setup")
PY
