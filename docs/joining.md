# Joining this server

This server is **private and whitelisted** - nobody can join without both a
Tailscale invite and a whitelist entry. No public IP, no port forwarding.

## What you need

### A Minecraft account

Two options:

- **Bedrock Edition** (phone/tablet/Windows/console - the common case for
  kids who already own the mobile app): requires being signed into a free
  Microsoft account within the Minecraft app. This is a platform
  requirement of Bedrock Edition itself, unrelated to our server - it
  applies to *any* multiplayer, not just this one.
  - For minors, this means a **Microsoft Family group** with the child as
    a managed child account under a parent's organizer account. This is
    the standard flow most Minecraft-playing families already go through;
    it doesn't require turning on heavy content restrictions if you don't
    want them - the parent just stays the account organizer, which
    Microsoft requires for legal child-consent reasons.
  - Console players additionally need their platform's own paid online
    subscription (Xbox Live Gold, PS Plus). Phone/tablet/Windows do not.
- **Java Edition**: a paid Java Edition account, played on PC/Mac. No
  Microsoft Family requirement, but requires purchasing Java Edition
  separately if you don't already own it, and a computer to run it on
  rather than a phone/tablet.

Each player needs **their own individual account** - not a shared one.
Sharing an account across multiple people breaks per-player identity on
the server (whitelist, GriefPrevention claims, inventory/progress would
all collide onto one shared identity).

### A Tailscale invite

You'll be invited via Tailscale's **Device Sharing** feature, not full
tailnet membership:

1. You'll receive a share link from the server admin.
2. Install [Tailscale](https://tailscale.com/download) on the device
   you'll play from.
3. Accept the invite.
4. This gives you access to **only this one server** - not the rest of the
   admin's home network. The share is additionally "quarantined": your
   device can only respond, never initiate connections on its own.

### A whitelist entry

Tell the admin your **exact in-game username** (case-sensitive):

- **Java Edition**: your Java username as-is.
- **Bedrock Edition**: your Bedrock username - the admin will add it with
  a `.` (dot) prefix internally (e.g. `aliceplays` → `.aliceplays`), but
  give them the plain name without the dot.

You can't join without this - `ENFORCE_WHITELIST` is on.

## Actually connecting

Once you have Tailscale connected and you're whitelisted:

- **Bedrock**: Minecraft app → **Play** → **Servers** tab → scroll to the
  bottom → **Add Server** → enter the server's Tailscale address and port
  `19132` (UDP).
- **Java**: Multiplayer → **Add Server** → enter the server's Tailscale
  address and port `25565` (TCP).

Ask the admin for the exact address (it's a Tailscale hostname, not a
public IP or domain).
