# Changelog

## 1.5.0

Android, iOS and React Native get the Flutter Digia-managed campaigns flow. Flutter is unchanged.

- Always ask: Digia-managed campaigns, or Digia with the CEP found (CleverTap, MoEngage or
  WebEngage when none is found), on every stack, even when the app already calls
  `Digia.initialize`.
- Digia-managed campaigns on Android (`tech.digia:engage`), iOS (`DigiaEngage` core) and React
  Native (`@digia-engage/core`): `initialize` only, no plugin. Add `Digia.trackEvent` in the
  analytics wrapper, next to each analytics event call, or at key actions, and
  `Digia.setUserAttributes` from the analytics user properties or the user model.
- React Native: `enableManagedCampaigns` is gone from the skill. No `digia-cep` docs link.
- iOS and React Native: Digia pods come from the Digia spec repo. Add the `digia-podspecs` and
  CDN `source` lines to the Podfile (Expo: `"plugins": ["@digia-engage/core"]`), run
  `pod install --repo-update`, and commit `Podfile.lock`.
- Anchors: the selected tab icon shares the key of its normal icon (Compose, `tabBarIcon`, custom
  SwiftUI tab buttons). System tab bars that cannot be wrapped: propose anchors on main buttons.
- Slots: add one at the top of the home screen and each static content screen without asking.
  Ask before adding one in a list, grid or form.
- Check: new AN-12..15, IO-12..16 and RN-18..21. AN-04 and IO-04 no longer apply to `digia`.
  RN-03 and RN-06 drop managed campaigns.

## 1.4.0

Flutter only. React Native, Android and iOS are unchanged.

- Always ask: Digia-managed campaigns, or Digia with the CEP found (CleverTap, MoEngage or
  WebEngage when none is found), even when the app already calls `Digia.initialize`.
- Digia-managed campaigns: add `Digia.trackEvent` in the analytics wrapper or next to each
  analytics event call, with the same names and properties, or at key actions when the app has no
  analytics. Add `Digia.setUserAttributes` from the analytics user properties or the user model.
  Not added with a CEP.
- `digia_engage` ^2.3.0. The `trackEvent` example no longer uses `value` and `currency`, which
  2.3.0 removed.
- Anchors: wrap `activeIcon` or `selectedIcon` with the same key as `icon`.
- Slots: add one at the top of the home screen and each static content screen without asking.
  Ask before adding one in a list, grid or form.
- No docs link for Digia-managed campaigns until the Flutter page exists.
- Check: FL-16 (events sent) is now a fail. New FL-17 (user attributes sent) and FL-18 (selected
  tab anchored).

## 1.3.1

- React Native and Flutter with no CleverTap, MoEngage or WebEngage: use Digia's own campaigns
  and do not ask. Other CEPs count as none found.

## 1.3.0

- Ask at the start, in one prompt: Digia with the CEP found, or Digia with its own campaigns
  (trigger + data), on React Native and Flutter; and the Digia API key, which the user can skip.
- API key placeholder is now `digia_xxx`.
- The summary lists each dependency override (app's version, Digia's version, why) and each static
  check error with its cause and fix.
- Do not stop for untracked agent skill folders such as `.agents/`, which installing the skill
  can create.
- README: install for Cursor with no files in the app's repository.

## 1.2.1

- Flutter CleverTap: `digia_engage_clevertap` 2.0.0 is on pub.dev. Flutter × CleverTap is supported.

## 1.2.0

- Flutter: add Digia-managed campaigns (`digia`) with `digia_engage` 2.2.0: no plugin,
  `Digia.trackEvent` and `Digia.setUserAttributes`. New checks FL-15 and FL-16.
- Flutter: require `digia_engage` 2.2.0.
- Do not build the app after the integration. Ask the user if they want help to build.
- Add anchors to the bottom navigation by default. Propose slots on screens with static content.
- Show the commands that open SDK Debug Settings on Android and iOS.
- Flutter: use `DigiaNavigatorObserver` alone. Pass a `navigatorKey` to `DigiaHost` only when the
  app already has one.
- Do not change the version of a package that the app already has. Flutter: add
  `dependency_overrides` and list each one in the summary.
- Add a short comment at each change in the app's code that says why.
- Run the static check, and tell the user each problem that the changes cause.

## 1.1.1

- CleverTap: add the account region. Flutter iOS needs only `CleverTap.autoIntegrate()`; the
  plugin registers the Digia template.
- React Native: pin `clevertap-react-native` 4.3.1 and `react-native-moengage` 12.5. Install
  `react-native-svg` and `@react-native-async-storage/async-storage`. Get the `DigiaEngage` pod
  from trunk. Add the Xcode 27 deployment target fix. Add `SDWebImage` with modular headers for
  CleverTap.
- React Native WebEngage: pin `react-native-webengage` 1.6.2 or a later 1.x.
- Flutter CleverTap: stop if `digia_engage_clevertap` 2.0.0 is not found. Do not fall back to 1.x.
- React Native MoEngage: add the native start steps, `plugin-base-bom` and Glide.
- React Native: use `environment: 'sandbox'` for a sandbox key. Track screens without a
  navigation library. Add `-destination` to the iOS build command.

## 1.1.0

- Flutter: pin the versions (`digia_engage` 2.1.0, the CEP plugins and their CEP SDKs), and
  upgrade `dio` after install.
- Flutter CleverTap: use `digia_engage_clevertap` 2.0.0.
- Android: use the callback form of `initialize`, and call `prepareCleverTapCustomTemplates()`
  for CleverTap. The debug deeplink needs no app step.
- iOS: the CEP plugins are public. Add CocoaPods. Builds from iOS 15.0; campaigns show from 17.0.
- MoEngage (Flutter and Android): add Glide. Without it, MoEngage stops the app on an image
  in-app campaign.
- Next steps: a CEP campaign needs its trigger event and the API key of its Digia project.
- Install with `npx skills`, Cursor, GitHub Copilot CLI and Gemini CLI.

## 1.0.0

- Add `setup-digia-engage`. It adds the Digia Engage SDK to a React Native, Flutter, Android or
  iOS app, or it checks an existing integration and reports each issue with its fix.
