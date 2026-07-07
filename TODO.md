# TODO

## Blocking the actual first deployment

- [x] ~~Decide Java vs. Bedrock with the other parents~~ - **decided:
  Bedrock**. See [`docs/account-decision.md`](docs/account-decision.md).
- [ ] Set up Microsoft Family accounts for the kids - see
  [`docs/joining.md`](docs/joining.md).
- [ ] Set up device-side app/time limits per
  [`docs/screen-time-controls.md`](docs/screen-time-controls.md) - note
  the iOS "All Apps & Categories" + stricter category limit interaction
  is inconsistently documented, test it on the actual device.
- [ ] Get everyone's exact in-game usernames and fill in `mc_whitelist`/
  `mc_ops` in `group_vars/all.yml` (Bedrock names need the `.` prefix -
  see [`docs/plugins.md`](docs/plugins.md)). Java names are pre-resolved
  automatically on deploy; Bedrock names need the post-connect
  `/fwhitelist`/`/op` procedure documented there. Admin, spouse, and one
  child are whitelisted so far (all Bedrock names needed the post-connect
  procedure - none matched the Gamertag first assumed, see
  [`docs/plugins.md`](docs/plugins.md#the-general-sanitization-pattern-confirmed-from-two-real-cases)).
- [x] ~~Run the actual first deployment~~ - **done**: Docker, Tailscale,
  firewall, SSH hardening, and the Minecraft stack are live on the
  mini-PC.
- [ ] Add remaining kids'/friends' real usernames once known (see above).
- [ ] Disable Tailscale key expiry for the `little-family-mincraft-server`
  device in the admin console (matching the other devices) - mentioned
  early on, never confirmed done.
- [x] ~~Revisit the Geyser/Java-version mismatch warning seen at boot~~ -
  **fixed**: added ViaVersion (see
  [`docs/plugins.md`](docs/plugins.md)) rather than bumping `mc_version`,
  since CoreProtect/ChatFilter have no `26.x` build yet.

## Follow-up once deployed

- [x] ~~Whitelist the admin's Bedrock account~~ - **done**, but not under
  the renamed Gamertag expected: the Xbox rename didn't carry over to
  the live Bedrock connection, so the server actually saw the old
  suffixed Gamertag with the `#` stripped - added via `/fwhitelist add`
  + `/op` (using the exact name from the server's own log) after
  connecting once with whitelist briefly opened. See
  [`docs/plugins.md`](docs/plugins.md#the-suffixed-modern-gamertag-case-name1234).
- [x] ~~Fix Bedrock chat being silently disabled~~ - **done**: turned off
  `enforce-secure-profile` (Bedrock/Floodgate players have no Mojang
  chat-signing key) - see [`docs/security.md`](docs/security.md#kid-safety).
- [ ] Confirm `/skin set <name>` actually works in-game for a real player
  (verified the plugin loads cleanly and resolves via Modrinth, not the
  in-game command itself). Also check whether the "Floodgate skin
  listener registered" log line means Bedrock players' real skins now
  show correctly to Java players, or just partial support - see
  [`docs/plugins.md`](docs/plugins.md).
- [ ] Live-fire test `make backup-restore` end to end against the real
  server (currently only verified via a throwaway `mc_data_dir` and the
  underlying tar semantics directly - see the commit history for
  `restore_backup.yml`).
- [ ] Confirm `make backup-pull` actually pulls real backup content once
  `itzg/mc-backup` has run at least once.
- [ ] Consider automating `make backup-pull` on a schedule (cron/launchd on
  the admin's Mac) rather than running it manually.
- [ ] Apply the updated [`tailscale/acl.hujson`](../tailscale/acl.hujson)
  grant (Glances + game-stats inbound, one combined grant now) via the
  admin console, flip `enable_home_assistant_stats: true`, and re-deploy -
  see [`docs/home-assistant.md`](docs/home-assistant.md). Also verify the
  RCON `list` output parsing (`mc_stats_server.py`) against a session
  with an actual player online, not just the 0-players case tested so far.
- [ ] Once the above is live, add Glances' own `--password` (one-time,
  interactive) for a second layer of auth on top of the network scoping -
  see [`docs/home-assistant.md`](docs/home-assistant.md#whats-deliberately-not-done).

## Security watch items

- [ ] `.trivyignore`'s gosu-CVE entries expire **2026-10-04** - re-verify
  the reasoning still holds (or that itzg has shipped a fix) before/at
  that date. See [`docs/security.md`](docs/security.md).
- [ ] Watch for `mc-image-helper` bumping its bundled `scala-library` past
  2.13.9 (resolves `CVE-2022-36944`, currently tracked but not suppressed).

## Publishing this repo

- [x] ~~Create the GitHub repo, push, confirm CI passes there~~ - **done**:
  public at [tomhanoldt/little-family-minecraft-server](https://github.com/tomhanoldt/little-family-minecraft-server),
  `main` has basic branch protection (no force-push, no deletion).
- [ ] Enable Dependabot **alerts** in repo settings (Settings → Code
  security and analysis) - `dependabot.yml` alone only covers
  version-update PRs, not the separate vulnerability-alert toggle.
- [ ] Enable GitHub **push protection** for secret scanning (Settings →
  Code security and analysis → Push protection) - secret scanning
  *alerts* are automatically on for public repos already (free, no
  action needed), but push protection (blocking a push containing a
  detected secret *before* it lands) is a separate toggle, off by
  default, that needs to be turned on explicitly even for public repos.
- [ ] Double check the `LICENSE` file's year/attribution still reads
  correctly whenever this is actually pushed.
- [ ] The planned blog post at [www.tomhanoldt.info](https://www.tomhanoldt.info) is drafted.
