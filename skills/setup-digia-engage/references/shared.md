# Shared

Facts that hold on every stack. The stack reference gives the code.

## Version floors

| Stack | Core | Platform |
|---|---|---|
| React Native | `@digia-engage/core` 3.4.0 | React Native 0.83+, React 19.2+; iOS pod iOS 15.0 |
| Android | `tech.digia:engage` 3.4.1 | `minSdk` 24 |
| iOS | `DigiaEngage` 4.4.0 | deployment target iOS 15.0 |
| Flutter | `digia_engage` 2.3.0 | Dart 3.6, Flutter 3.29; iOS deployment target 15.0 |

Older core versions do not run Digia-managed campaigns. On Android, 3.4.0 and earlier also lack the
`@Composable` annotations in the published artifact, so a Compose app crashes at launch with
`NoSuchMethodError` on `DigiaHost`; use 3.4.1 or later. On iOS, the app builds from 15.0, but
campaigns show only on iOS 17 and later, on every stack. If the target is below 17.0, tell the
user.

## Call order

Use this order at app start:

1. Start the CEP SDK, as its own docs say.
2. CleverTap only: the prepare call, `DigiaCleverTapPlugin.prepareCleverTapCustomTemplates()`
   (Flutter: none, the plugin does it).
3. `Digia.register(<plugin>)`. Not for `digia`.
4. `Digia.initialize(...)`. Waiting for it is optional.

`register` works before or after `initialize` on every stack: the SDK attaches the plugin either
way. Register early anyway, right after the CEP start, so the plugin sees CEP triggers from the
first one. Flutter starts `initialize`, then registers on the next line: see
[flutter.md](flutter.md). iOS WebEngage drops an in-app that arrives before `register`: see
[ios.md](ios.md).

## Held before ready

`initialize` returns once campaigns load, or after 2 seconds. Until campaigns are ready:

- CEP triggers wait in a buffer of 20 per plugin, for up to 5 minutes. A newer trigger for the
  same CEP campaign replaces the held one. A full buffer drops the oldest. They show when Digia is
  ready.
- Digia-managed signals (app open, screen views, events) are held for up to 10 seconds and
  replayed in order. Older ones, and anything past 200, are dropped.
- `trackEvent` and `setUserAttributes` called before `initialize` are ignored. Call them only
  after `initialize` has started.

## Debug log lines

Set `logLevel` to verbose to see these.

| Log line | Meaning |
|---|---|
| `trackEvent() ignored — called before initialize()` | Move the call after `Digia.initialize`. `setUserAttributes()` logs the same. |
| `Dropped — not found in the campaign store` | Flutter. Usually a wrong API key: it must be from the Digia project that has the campaign. |
| `register() ignored — called before initialize()…` | Flutter only. The plugin is still attached. Start `initialize` first, as [flutter.md](flutter.md) says, to avoid the line. |
| `Dropping in-app — no host attached (reason=not_ready…)` | iOS WebEngage: the in-app arrived before `register`. Register right after the WebEngage start. |
| `Held until Digia is ready` | iOS WebEngage: the in-app is held and shows when Digia is ready. |

## Gamification

Only when the client's Digia project has gamification turned on. Not everyone has it. The server
picks each outcome. The SDK shows the games and draws the rewards page. Docs:
`docs.digia.tech/developer/<setup>/gamification`, with `<setup>` one of `digia-cep`, `clevertap`,
`moengage` or `webengage`.

Version floor: the first core release with gamification, on each stack. It is `TBD`: no release
has it yet. Flutter has no gamification.

**User verification.** Gamification needs `Digia.setUserId`. With **Project settings → User
verification** on in the dashboard, the app also passes `userHash`: HMAC-SHA256 of the trimmed
user ID, keyed with that secret, as lowercase hex. Only the app's server computes it. Never put
the secret in the app. With verification on and the hash missing or wrong:

- A campaign that tries to start a game shows nothing. The server answers `notVerified`, and the
  campaign timeline shows `user_not_verified`.
- The rewards page gets HTTP 401 and shows its empty state.

A call with no user ID is refused even with verification off. With verification off, any user ID
is accepted and a campaign with rewards shows a go-live warning. The SDK keeps the user ID and
hash across launches. `clearUserId` clears both.

**Rewards page.** Full screen, drawn by the SDK: the user's game chances and their active, used
and expired rewards. It needs an initialized SDK and a user. It closes an open game first. Test
plays do not show on it. A link that ends in `_digia/rewards`, such as `myapp://_digia/rewards`,
opens it. The SDK does not own the scheme: the app registers its own.

**Floating entry and teaser.** No code. They show in the slot key `digia_rewards_widget`, which
the SDK handles.

**Reward links.** A reward's button follows its link. Placeholders: `{{code}}` (coupon rewards
only), `{{grantId}}`, `{{rewardKey}}`, `{{campaignKey}}`. Routing:

| Link | Goes to | Page or game |
|---|---|---|
| `http` or `https` | `actionHandlers` open-URL handler, else the system browser | The rewards page stays open. A game closes. |
| Any other scheme | `actionHandlers` deep-link handler, else the system | Closes first. |
| `javascript`, `data`, `file`, `blob`, `vbscript`, `intent`, `content` (iOS: not `content`) | Blocked, only logged | Stays. |

A link with no scheme is refused. Use the app's own scheme for links into the app: an `https` link
to the app's domain may open the browser instead. Treat the link as untrusted input. Tapping a
reward does not mark it used.

**Server side**, for the user to hand to their backend team:

- Compute `userHash`, as above.
- Webhooks `reward.won` and `submission-created`, with the signature check. `reward.won` does not
  carry the reward link.
- The reward used callback: the server tells Digia when a reward is used.
