# Decision: Java Edition vs. Bedrock Edition for the kids

For discussion with the other parents. Written to be readable without any
technical background. This document is the base for making that decision -
it doesn't assume one has been made yet.

## Microsoft account required

A Microsoft account is required for either edition today - "Mojang
accounts" (the old login system that didn't need one) no longer exist.
Since the kids are minors, that account has to go through a **Microsoft
Family group**: a free setup where a parent is the "organizer" and the
child account exists under that family group. This is a standard, common
flow (most families with kids on Xbox/Minecraft already do this) and does
**not** require turning on heavy content restrictions or monitoring - the
parent just has to be the organizer, which Microsoft requires for legal
child-consent reasons in most countries.

## The actual comparison

| | **Bedrock Edition** | **Java Edition** |
|---|---|---|
| Devices | Phone, tablet, Windows, console | PC/Mac only - **not** phone/tablet/console |
| Cost | Already owned (purchased on iOS/Android) | ~€30/$30 per child - as of 2026, Java is no longer sold standalone; it's bundled with a PC copy of Bedrock in one purchase |
| Microsoft account for minors | Required (Family group) | Required (Family group) - same as Bedrock |
| Works with this server | Yes, already set up and tested (via Geyser/Floodgate) | Yes, natively (no extra setup needed) |
| Plugin/mod ecosystem | Limited to what a Java server exposes via Geyser translation | Full - but this server's plugins already work fine either way |

## Recommendation

**Bedrock**, given:

1. It's already owned - no new purchase needed for any of the kids.
2. It runs on the devices they already have (phones/tablets), not a
   requirement to use a PC/Mac.
3. This server already has Bedrock support built, configured, and tested
   (Geyser + Floodgate) - nothing extra to set up.
4. The Microsoft-account requirement and cost of setting that up is
   identical either way, so it isn't a factor in choosing between them.

The only reason to pick Java instead: if the kids specifically want to
play on a PC/Mac rather than a phone/tablet, or want access to
Java-specific mods/features beyond what this server's plugin set offers -
at the cost of a ~€30/$30 purchase per child.

## Restricting who they can play with (important limitation)

**There is no way to restrict a Microsoft/Xbox child account to only this
one server.** Checked directly - Microsoft's own controls are broad on/off
toggles ("allow multiplayer," "allow cross-network play," "allow playing
with people not on your friends list"), not a per-server allowlist. Once
multiplayer is turned on so they can reach our server, they can also type
in any other server's address - Minecraft doesn't check with Microsoft
about which addresses a child account may connect to.

What actually helps, layered:

- **Set "play with people not on your friends list" to blocked** in Xbox
  privacy/Family Safety settings. This is account-wide and applies no
  matter which device they sign in from (iOS, Android, Windows) - verified
  this isn't platform-specific. It doesn't stop them adding another server
  by address, but it blocks strangers from messaging/inviting them, which
  is most of the actual risk on public servers.
- **A house rule, not a technical lock**, for "we only play on our
  server" - realistic for younger kids, not a guarantee for an
  older/technical one.
- **A real technical guarantee would need to live outside Minecraft
  entirely** (device/router-level network restrictions) - a bigger,
  separate undertaking; see [`joining.md`](joining.md) and
  [`screen-time-controls.md`](screen-time-controls.md) for what device-side
  controls *are* practical to set up.

## What each parent needs to do (if going with Bedrock)

1. Set up a Microsoft Family group (if not already done) with your child
   as a managed child account. One-time, ~10 minutes.
2. Sign the child into the Minecraft app with that account.
3. Send the server admin your child's **exact in-game Bedrock username**
   (not their Microsoft account email/name).
4. Accept the Tailscale invite link the admin sends you and install
   Tailscale on the device.
5. Consider setting up device-side screen time/app controls - see
   [`screen-time-controls.md`](screen-time-controls.md).

See [`joining.md`](joining.md) for the full step-by-step once this
decision is made.
