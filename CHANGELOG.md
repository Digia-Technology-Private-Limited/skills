# Changelog

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
