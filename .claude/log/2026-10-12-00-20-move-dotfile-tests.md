---
branch: 2026-10-12-00-20-move_dotfile-tests
opened: 2026-10-12T00:20:38+09:00
request: Move deployment tests from nguekwang/pjt-transfer-previous-accounts.
---

## Log

- Started from clean dotfiles main 7b72ade; no pre-existing test or .claude
  configuration was overwritten.
- Preserved the runner and helper; adapted deployment checks for home/ and the
  link user/link sudo interface. Directory links and fcitx5 expansion are covered.
- Retired the former migration test because setup.sh has no migration runner.
  Replaced obsolete exemptions with an empty, documented allowlist.
- Ported the advisory wiring hook without the personal repository's hooklib
  dependency. Registered only that hook and the deployment skill locally.
- Validated missing-source, unwired-file and missing-step failures, plus hook
  warning/ignore/success paths. All three test files pass with 11 ok assertions.
- Did not execute setup.sh, install packages, edit user settings, commit or push.
