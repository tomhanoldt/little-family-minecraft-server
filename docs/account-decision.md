# Decision: Java Edition vs. Bedrock Edition for the kids

For discussion with the other parents. Written to be readable without any
technical background.

## Correcting a mistake first

Earlier in setting this up, it was assumed Java Edition wouldn't require a
Microsoft account the way Bedrock does. That's **wrong** - checked and
confirmed: Microsoft account sign-in has been mandatory for Java Edition
too since March 2022 (fully enforced since December 2023). "Mojang
accounts" (the old login system that didn't need a Microsoft account)
don't exist anymore for new use. **Both editions require a Microsoft
account today** - this isn't a lever either choice avoids.

Since a Microsoft account is unavoidable either way, and the kids are
minors, that account has to go through a **Microsoft Family group**: a
free setup where a parent is the "organizer" of the account and the child
account exists under that family group. This is a standard, common flow
(most families with kids on Xbox/Minecraft already do this) and does
**not** require turning on heavy content restrictions or monitoring - the
parent just has to be the organizer, which Microsoft requires for legal
child-consent reasons in most countries.

## The actual comparison

| | **Bedrock Edition** | **Java Edition** |
|---|---|---|
| Devices | Phone, tablet, Windows, console | PC/Mac only - **not** phone/tablet/console |
| Cost | Already owned (purchased on iOS/Android) | New purchase per child (Java Edition license) |
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
4. The Microsoft-account requirement is identical either way, so it isn't
   a factor in choosing between them.

The only reason to pick Java instead: if the kids specifically want to
play on a PC/Mac rather than a phone/tablet, or want access to
Java-specific mods/features beyond what this server's plugin set offers.

## What each parent needs to do (if going with Bedrock)

1. Set up a Microsoft Family group (if not already done) with your child
   as a managed child account. One-time, ~10 minutes.
2. Sign the child into the Minecraft app with that account.
3. Send the server admin your child's **exact in-game Bedrock username**
   (not their Microsoft account email/name).
4. Accept the Tailscale invite link the admin sends you and install
   Tailscale on the device.

See [`joining.md`](joining.md) for the full step-by-step once this
decision is made.
