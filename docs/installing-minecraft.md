# Installing the Minecraft client

Where to actually get the app, per device - separate from
[`joining.md`](joining.md) (accounts, whitelist, Tailscale) and
[`account-decision.md`](account-decision.md) (Java vs. Bedrock, which
one to pick). This assumes that decision is already made.

## Phone / tablet (Bedrock)

- **iOS/iPadOS**: App Store → search **Minecraft** → install. This is
  the Bedrock app - the same one across every non-PC platform.
- **Android**: Play Store → search **Minecraft** → install. Same
  Bedrock app as iOS.

Either way: first launch prompts a Microsoft account sign-in (see
[`joining.md`](joining.md#a-minecraft-account) for the Family/child
account setup, and
[`joining.md`](joining.md#getting-your-bedrock-username-if-you-dont-have-one-yet)
for how your in-game username gets set on first sign-in). If it's not
already owned, the App/Play Store will prompt to buy it once.

## Laptop / PC

**Windows**: either edition works.
- Bedrock: Microsoft Store → search **Minecraft**.
- Java: [minecraft.net/download](https://www.minecraft.net/en-us/download)
  → **Download for Windows** → run the installer.

**Mac**: **Java Edition only** - Bedrock has no official Mac client at
all (not "harder to install," genuinely not offered, see below).
1. [minecraft.net/download](https://www.minecraft.net/en-us/download) →
   **Download for macOS** → this gets you a `.dmg`.
2. Open it, install the Minecraft Launcher.
3. Launch it, sign in with a Microsoft account (can be the same account
   used on a phone, or a different one - Java and Bedrock are separate
   identities either way, see below).
4. If not already owned, you'll be prompted to buy it - as of 2026 it's
   sold bundled with a PC copy of Bedrock, ~€30/$30 (see
   [`account-decision.md`](account-decision.md)), not standalone anymore.
5. First launch downloads the actual game - a few minutes depending on
   connection.

Works identically on Apple Silicon (M1 and later) and Intel Macs.

**Linux**: same as Mac - Java Edition only, same launcher/download page.

### Java: pick the matching version, not "latest"

This server runs a specific **pinned** Minecraft version (currently
`1.21.4` - ask the admin if unsure, since this can change; see
`mc_version` in `group_vars/all.yml` if you're the admin). Vanilla Java
clients require an **exact version match** to connect - the Minecraft
Launcher defaults new installations to the newest release, which is
usually *not* this server's pinned version, and shows an "incompatible
version" error in the server list if they don't match.

To fix it:
1. Minecraft Launcher → **Installations** tab.
2. **New Installation** → under **Version**, pick the exact pinned
   release (e.g. `1.21.4`) from the dropdown - not "latest release".
3. Save, then make sure you **launch using that installation** (select
   it from the dropdown on the Launcher's main Play screen) before
   adding/joining the server.

If the server's pinned version ever changes, you'd need to switch
installations to match again - the admin will let you know.

## "Why can't I just install the iPhone/iPad Minecraft app on my Mac?"

Reasonable question, since Apple Silicon Macs (M1 and later) *can*
generally run iPhone/iPad App Store apps directly, no emulator needed -
this isn't limited to Minecraft. Whether a given app is offered that way
is a **developer opt-in/opt-out choice**, not something Apple forces
either way (see
[Apple's own developer docs on this setting](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-macs-with-apple-silicon/)).

Mojang/Microsoft has deliberately **opted out** for Minecraft - the iOS
app doesn't show up as installable on Mac in the App Store, even though
nothing technically stops the binary from running there. This lines up
with the fact that Bedrock has never had an officially supported Mac
release through *any* channel (no Microsoft Store equivalent, no direct
download) - it reads as a deliberate support-scope decision (not
shipping a Mac experience they haven't built/tested keyboard-and-mouse
controls, server browser UI, etc. for) rather than a technical
limitation. This has been a recurring, unresolved request from the
Minecraft community, not something specific to this server or setup.

Practically: if you want Minecraft on a Mac, Java Edition (above) is the
actual, supported path - not a workaround.

## One account, two identities

Worth being explicit about: your **Java username** and your **Bedrock
Xbox Gamertag** are two separate identities, even when signed in with
the exact same Microsoft account on both. Installing both clients (e.g.
phone + Mac) to test the same server means **two separate whitelist
entries** - see [`joining.md`](joining.md#a-whitelist-entry).
