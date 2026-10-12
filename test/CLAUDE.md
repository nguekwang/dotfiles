# Deployment tests

Run `sh test/all` from the repository root. Tests read setup.sh and configuration
sources without executing setup.sh, installing packages, using sudo or changing
the host. Scratch fixtures are confined to mktemp directories and removed.

- all and base-test.sh retain the runner/helper migrated from
  nguekwang/pjt-transfer-previous-accounts.
- deployment-test.sh validates shell syntax, the link helper, declared setup
  functions, literal/dynamic link sources, directory links and coverage of home/
  and etc/ files. An unwired exemption must exist and carry a reason.
- detection-test.sh checks that missing sources, unwired files and missing step
  functions really fail the deployment test.
- hook-test.sh checks the relocated hook against an unwired temporary fixture.
- unwired-files.txt is intentionally empty except for its format header: all
  current deployment sources are wired. Obsolete user/ and etc/ exemptions from
  the old repository do not apply here.

The former migrations-test.sh depended on setup_migrate and a migrations/
directory that this setup does not provide. It is retired rather than installed
as a permanently skipped or failing test. Do not execute setup.sh in these tests.
