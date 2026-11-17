# Shared

Facts that hold on every stack. The stack reference gives the code.

## Version floors

| Stack | Core | Platform |
|---|---|---|
| React Native | `@digia-engage/core` 3.4.0 | React Native 0.83+, React 19.2+; iOS pod iOS 15.0 |
| Android | `tech.digia:engage` 3.4.0 | `minSdk` 24 |
| iOS | `DigiaEngage` 4.4.0 | deployment target iOS 15.0 |
| Flutter | `digia_engage` 2.3.0 | Dart 3.6, Flutter 3.29; iOS deployment target 15.0 |

Older core versions do not run Digia-managed campaigns. On iOS, the app builds from 15.0, but
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
