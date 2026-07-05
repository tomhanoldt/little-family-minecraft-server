# Joining this server

This server is **private and whitelisted** - nobody can join without both a
Tailscale invite and a whitelist entry. No public IP, no port forwarding.

Before joining, parents may want to read
[`privacy.md`](privacy.md) - what's logged (chat, world actions via
CoreProtect), who can see it, and how that data is protected.

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
- **Java Edition**: a paid account (bundled with a PC copy of Bedrock as of
  2026 - see [`account-decision.md`](account-decision.md) for current
  pricing), played on PC/Mac rather than phone/tablet. Also requires the
  same Microsoft Family setup for minors as Bedrock - this isn't something
  either edition avoids.

Each player needs **their own individual account** - not a shared one.
Sharing an account across multiple people breaks per-player identity on
the server (whitelist, GriefPrevention claims, inventory/progress would
all collide onto one shared identity).

### Setting up the Microsoft Family group and child account

This is separate from, and doesn't require, your kid already having an
Apple ID or Google Account - see
[`device-accounts.md`](device-accounts.md) for that (device-level)
account layer, which you'll also want for app-store access and the
[screen-time controls](screen-time-controls.md), just not as a
prerequisite for the steps below.

If you don't already have this set up:

1. Sign in at [family.microsoft.com](https://family.microsoft.com) with
   your own Microsoft account (this makes you the "organizer").
2. Select **Add a family member** → choose **Member** for a child (not
   **Organizer**, which is for adults).
3. If your child already has a Microsoft account, enter its email. If not,
   select **Create one** → **Get a new email address** to create a new
   `@outlook.com` address for them as part of this same flow - you don't
   need to set anything up separately first.
4. Enter their name and date of birth. Since they're a minor, you'll be
   prompted to give parental consent - this is Microsoft's own legal
   requirement, not something this server adds.
5. Sign the child into the Minecraft app using that new account.

### Adding another child as a friend

If your kids are on Xbox privacy settings that restrict play to friends
only (recommended - see [`account-decision.md`](account-decision.md)),
two children from *different* families need to actually be Xbox friends
for this to work, and this requires **parental approval on both sides**,
not just the kids adding each other:

1. One child sends a friend request by searching the other's gamertag
   (Xbox app or in-game: People → Find someone).
2. If parental approval is enabled (the default for child accounts), the
   *sending* child's parent must approve the request being sent.
3. The *receiving* child's parent must then approve accepting it.
4. Both parents can manage this via the
   [Xbox Family Settings app](https://www.xbox.com/en-US/apps/family-settings-app)
   on their own phone, which sends a real-time notification for incoming
   requests rather than requiring you to be at the console/PC.

Coordinate with the other parent so both approvals actually happen -
otherwise the request just sits pending.

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
