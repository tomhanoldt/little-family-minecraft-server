# TODO

## Blocking the actual first deployment

- [ ] **Decide Java vs. Bedrock with the other parents** - see
  [`docs/account-decision.md`](docs/account-decision.md).
- [ ] Set up Microsoft Family accounts for the kids (once the above is
  decided) - see [`docs/joining.md`](docs/joining.md).
- [ ] Set up device-side app/time limits per
  [`docs/screen-time-controls.md`](docs/screen-time-controls.md) - note
  the iOS "All Apps & Categories" + stricter category limit interaction
  is inconsistently documented, test it on the actual device.
- [ ] Get everyone's exact in-game usernames and fill in `mc_whitelist`/
  `mc_ops` in `group_vars/all.yml` (Bedrock names need the `.` prefix -
  see [`docs/plugins.md`](docs/plugins.md)).
- [ ] Run the actual first deployment (`make ansible-deploy`, untagged/full
  run) - Docker isn't installed on the mini-PC yet, and the real Minecraft
  stack has never been started there.
- [ ] Disable Tailscale key expiry for the `little-family-mincraft-server`
  device in the admin console (matching the other devices) - mentioned
  early on, never confirmed done.

## Follow-up once deployed

- [ ] Live-fire test `make backup-restore` end to end against the real
  server (currently only verified via a throwaway `mc_data_dir` and the
  underlying tar semantics directly - see the commit history for
  `restore_backup.yml`).
- [ ] Confirm `make backup-pull` actually pulls real backup content once
  `itzg/mc-backup` has run at least once.
- [ ] Consider automating `make backup-pull` on a schedule (cron/launchd on
  the admin's Mac) rather than running it manually.

## Security watch items

- [ ] `.trivyignore`'s gosu-CVE entries expire **2026-10-04** - re-verify
  the reasoning still holds (or that itzg has shipped a fix) before/at
  that date. See [`docs/security.md`](docs/security.md).
- [ ] Watch for `mc-image-helper` bumping its bundled `scala-library` past
  2.13.9 (resolves `CVE-2022-36944`, currently tracked but not suppressed).

## Before publishing this repo (if ever)

- [ ] Final call on whether/when to make this public - git history has
  already been scrubbed (author identity, no secrets/PII in any commit)
  in preparation, but no remote exists yet and nothing has been pushed.
- [ ] If publishing: create the GitHub repo, push, confirm the CI
  workflows (`lint.yml`, `verify.yml`, `security.yml`) actually pass
  there, and enable Dependabot alerts in repo settings (`dependabot.yml`
  alone only covers version-update PRs, not the separate
  vulnerability-alert toggle).
