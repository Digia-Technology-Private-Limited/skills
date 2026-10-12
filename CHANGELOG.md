# Changelog

## 1.1.0

- Flutter: pin the tested versions (`digia_engage` 2.1.0, the CEP plugins and their CEP SDKs), and
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
