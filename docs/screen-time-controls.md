# Controlling app usage time and allowed apps

Device-side controls for how long and which apps the kids can use - on
iOS/iPadOS (Apple Screen Time) and Android (Google Family Link). This is
separate from and in addition to the Microsoft/Xbox account settings
covered in [`account-decision.md`](account-decision.md) - that document
controls *who they can play with*, this one controls *how long and what*.

## The kind of setup this covers

The example used throughout: **2 hours total of any allowed app per day,
but only 1 hour of that can be games/video/media apps** - i.e. a broad
daily budget with a stricter sub-limit for the categories you care most
about.

## Android (Google Family Link)

Requires the child to have a Google Account managed via Family Link (same
kind of setup as Microsoft Family - a parent is the manager, the child's
account exists under it).

- **Daily device limit**: an overall cap on total device use per day.
- **Category limits**: Family Link supports limiting entire categories
  (e.g. "Games") as a group, not just one app at a time.
- **Per-app limits**: a specific limit for one app, if you want to single
  one out (e.g. Minecraft specifically, rather than the whole Games
  category).
- **Unlimited-time apps**: specific apps can be exempted from the daily
  limit entirely (useful for e.g. a reading or school app).

These operate **independently, and whichever is more restrictive applies**
- confirmed from Google's own documentation. Concretely, for the 2-hour/
1-hour example: set the **daily device limit to 2 hours**, and separately
set the **"Games" category limit to 1 hour**. Games become unavailable
after 1 hour even though 1 hour of overall device time remains; other
allowed apps keep working until the full 2-hour budget runs out (or until
bedtime/downtime, if configured).

Setup: Family Link app → select child → **Screen time** → **Daily limit**
(overall) and **App activity → set a limit** (per app or category).

## iOS / iPadOS (Apple Screen Time)

Requires the child's device to be part of your **Family Sharing** group so
you can manage it remotely from your own device (or a Screen Time passcode
set directly on the child's device if not using Family Sharing).

- **App Limits**: restrict specific apps or categories (e.g. "Games",
  "Social", "Entertainment") to a daily time budget.
- **All Apps & Categories**: a single blanket limit covering everything.
- **Downtime**: a schedule (e.g. bedtime) during which only apps you've
  explicitly marked "Always Allowed" can be used.
- **Communication Limits** and **Content & Privacy Restrictions**: separate
  controls for who they can contact and what content/purchases are
  allowed.

**Important honesty note**: unlike Android, Apple's own support
documentation and community reports on how a blanket "All Apps &
Categories" limit interacts with a *more specific, stricter* category
limit (e.g. 2 hours overall but 1 hour for Games) are **inconsistent** -
some report the specific limit is honored within the overall budget
exactly like the Android example above, others report the blanket limit
overrides the specific one entirely. This may depend on the iOS version.
**Test this directly on the actual device before relying on it** rather
than assuming either behavior.

The reliably-documented, unambiguous way to get *at least* the "1 hour of
games" half of the goal: set a single **App Limit on the "Games" category
(or on Minecraft specifically)** to 1 hour, without trying to combine it
with a separate "All Apps & Categories" limit. If you also want an overall
daily device budget and it doesn't combine the way you expect, Downtime
(with everything except a chosen allowlist blocked after a certain time)
is a more reliably-documented way to cap total use for the day.

Setup: Settings → **Screen Time** → **App Limits** → **Add Limit** (choose
category or specific apps, set the time) and/or → **Downtime**.

## Applies to Minecraft the same as any other app

Both platforms treat Minecraft as just another app for these purposes -
whichever category you file it under (typically "Games") gets whatever
limit you set for that category, or set a limit on the Minecraft app
specifically if you don't want it lumped in with other games.
