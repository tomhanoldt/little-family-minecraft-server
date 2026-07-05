# Setting up your kid's device account (Apple ID / Google Account)

Before the [Microsoft account](joining.md#setting-up-the-microsoft-family-group-and-child-account)
needed for Minecraft/Xbox, there's a separate, independent account layer:
the device's own account (Apple ID on iOS/iPadOS, Google Account on
Android). This is what the App Store/Play Store, and the
[screen-time controls](screen-time-controls.md) (Family Sharing / Family
Link) actually hook into - it's not the same account as the Microsoft
one, and you don't need one to get the other (Microsoft account creation
can generate its own fresh email inline - see
[`joining.md`](joining.md#setting-up-the-microsoft-family-group-and-child-account)).

## Apple: creating a child Apple ID via Family Sharing

1. **Settings** app → **Family** (or your own name → **Family Sharing**)
   → **Add Member** → **Create Child Account** → follow the prompts
   (name, birthdate). Some countries require the organizer to verify
   they're an adult (e.g. a credit card or ID) before finishing.
2. Apple frames this as a **Child Account** for anyone under 18, not a
   strict "under 13 only" thing - the exact age threshold for *requiring*
   a parent-created account (vs. a normal self-managed one) varies by
   country/local age of consent.

**What's automatic vs. what you still have to configure:**
- **Under 13** (roughly): `Ask to Buy` is on and, in some regions,
  can't be turned off; baseline content restrictions and Screen Time
  enforcement apply automatically.
- **13-17**: similar baseline protections apply (web content filtering,
  Communication Safety), but `Ask to Buy` is optional - the organizer
  can turn it on, it isn't forced.
- Either way, **Screen Time itself (downtime, app limits, communication
  limits) is not pre-populated** - you still have to configure the
  actual schedule/limits yourself, see
  [`screen-time-controls.md`](screen-time-controls.md).

**Recovery**: Apple's stated design is that a child account's password
recovery routes to the **family organizer's** email, not the child's -
so losing/forgetting the child's password is recoverable by the parent
via appleid.apple.com. Worth flagging honestly: multiple parents report
in Apple's own community forums that this doesn't always behave as
documented (some report reset emails going to the child's address
instead, or no rescue option being offered at all) - don't treat this as
a guarantee, and set up an explicit
[recovery contact](https://support.apple.com/en-us/102641) yourself
rather than relying on the default.

## Google: creating a child account via Family Link

1. Parent installs the **Family Link** app → **Add child** →
   **Create account** → choose "No" when asked if the child already has
   an account → enter name, birthday, email, password → parent signs in
   with their own Google Account to give consent and pick settings.
   Takes about 15 minutes.
2. **Under 13** (or the local age of consent): a fully parent-created,
   fully supervised account.
3. **At 13+** (age varies by country): the account can convert to a
   "supervised teen account" with more autonomy - the child gains more
   control, but a parent still has to approve before supervision is
   switched off entirely (only allowed once the child is 13+, mandatory
   until 18).
4. Note the **EU has a different flow** for 13-15 year olds - they go
   through the standard Android device setup rather than the Family
   Link child-creation path. Worth checking Google's current docs if
   this applies to you, since it wasn't independently cross-verified
   beyond Google's own page.

**What's automatic vs. what you still have to configure:** supervision
itself (Family Link monitoring, restricted Search/Chrome/Gmail) applies
automatically at creation. Google Play **purchase approval** and
**content-maturity filtering** exist for both child and teen tiers, but
you have to actively turn them on - they're not forced defaults the way
Apple's `Ask to Buy` can be. (Ad-personalization restrictions for child
accounts are Google's stated policy, but the exact toggle/behavior
wasn't independently confirmed here - worth checking directly in
Family Link's settings rather than assuming a specific default.)

## Security practices for either

- **Keep the recovery email/phone current, and make it yours (the
  parent's), not the child's** - both platforms' account-recovery flows
  ultimately depend on reaching *someone* who can prove control of the
  account; a kid who forgets a password and has no working recovery
  contact leads into a slow manual support/appeals process on both
  platforms.
- **Hold the password yourself** (or store it in a family-shared
  password manager - Google Password Manager now supports sharing
  saved passwords within a family group). This isn't an explicit
  Apple/Google policy requirement, just consensus best practice: it
  means you can actually help if the kid gets locked out, and you
  retain the ability to review/manage the account.

## Reusing this email for the Microsoft account, or keeping them separate?

Technically, either works: Microsoft account sign-up accepts an existing
Gmail/iCloud address as its sign-in email (the only hard restriction is
that an email already tied to *another* Microsoft account can't be
reused - that's unrelated to using an outside provider's address at
all). Neither Apple, Google, nor Microsoft has a stated recommendation
either way, so this is a judgment call, not a rule:

- **Reuse the existing Apple ID/Google email**: one less password to
  manage, one less account to keep track of.
- **Keep them separate** (e.g. the fresh `@outlook.com` address created
  inline during Microsoft Family setup - see
  [`joining.md`](joining.md#setting-up-the-microsoft-family-group-and-child-account)):
  a problem with one account (lost password, compromise) doesn't cascade
  into the other. Generally the safer default when in doubt.
