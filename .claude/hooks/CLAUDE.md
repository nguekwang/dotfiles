# Deployment hook

check-dotfile-wiring.py runs the read-only deployment test after editing home/,
etc/, setup.sh or the exemption list. It reports failures as additional context,
does not block edits and never runs setup.sh. Python 3 is required. Remove its
handler from ../settings.json to disable it.
