# iOS

Docs: `https://www.digia.tech/docs/developer/<cep>` (`clevertap`, `moengage`, `webengage`).
Digia-managed campaigns are not available on iOS yet: ask the user which CEP to use.

## Dependencies

Add the CEP plugin package with Swift Package Manager, at its latest tag. It brings the
`DigiaEngage` core with it. Do not add a second core package: SPM then finds `DigiaEngage` twice
and resolution fails.

| CEP | Package URL | Product |
|---|---|---|
| clevertap | `https://github.com/Digia-Technology-Private-Limited/de_ios_clevertap.git` | `DigiaEngageCleverTap` |
| moengage | `https://github.com/Digia-Technology-Private-Limited/de_ios_moengage.git` | `DigiaMoEngage` |
| webengage | `https://github.com/Digia-Technology-Private-Limited/de_ios_webengage.git` | `DigiaEngageWebEngage` |

Get the latest tag with `git ls-remote --tags <url>`. Edit `Package.swift`, or the Xcode project
package references.

If the app has a `Podfile` and no SPM packages, use CocoaPods: add `pod '<Product>'` (for example
`pod 'DigiaMoEngage'`) and run `pod install`.

Set the deployment target to iOS 15.0 or later. The SDK shows nothing below iOS 17.0. If the target
is below 17.0, tell the user.

## Initialize and register

In the app's launch code (`App.init` with SwiftUI, or `application(_:didFinishLaunchingWithOptions:)`):

```swift
import DigiaEngage
import DigiaEngageCleverTap

Task {
    try await Digia.initialize(DigiaConfig(apiKey: "YOUR_API_KEY"))
    Digia.register(DigiaCleverTapPlugin())
}
```

| CEP | Import | Register call |
|---|---|---|
| clevertap | `DigiaEngageCleverTap` | `Digia.register(DigiaCleverTapPlugin())` |
| moengage | `DigiaMoEngage` | `Digia.register(MoEngagePlugin())` |
| webengage | `DigiaEngageWebEngage` | `Digia.register(DigiaWebEngagePlugin())` |

Start the CEP SDK before `register`. Register one plugin.

## CEP native steps

- CleverTap: before `register`, call `DigiaCleverTapPlugin.prepareCleverTapCustomTemplates()`
  then `CleverTap.autoIntegrate()`. Add `CleverTapAccountID` and `CleverTapToken` to
  `Info.plist`. Ask the user for them. If they skip, write `YOUR_CLEVERTAP_ACCOUNT_ID` and
  `YOUR_CLEVERTAP_TOKEN`. If the account has a region (for example `in1`), also add
  `CleverTapRegion`.
- MoEngage: start MoEngage with `MoEngage.sharedInstance.initializeDefaultInstance(...)` as its
  docs say, before `register`.
- WebEngage: start WebEngage with the Digia delegate. WebEngage accepts one delegate, at start only:

  ```swift
  WebEngage.sharedInstance().application(application,
      didFinishLaunchingWithOptions: launchOptions,
      notificationDelegate: DigiaWebEngagePlugin.notificationDelegate)
  ```

  The plugin bundles the WebEngage SDK. Remove a separate WebEngage package or pod before you add
  the plugin.

## Host

SwiftUI: wrap the root view once.

```swift
WindowGroup { DigiaHost { ContentView() } }
```

UIKit: host the root view controller's view in `DigiaHost` with `UIHostingController`, or follow
the UIKit section of the docs.

## Screen tracking

SwiftUI: call `Digia.setCurrentScreen(name: "home")` in `.onAppear` of each screen. UIKit: call
`digiaScreen("home")` in `viewDidAppear`. The names must match the screen names in the Digia
dashboard, case included.

## Identity

Next to the app's login and logout code: `Digia.setUserId(user.id)`, then on logout
`Digia.clearUserId()` and `Digia.clearAllInlineContent()`. Keep the CEP's own login call.

## Debug deeplink

Add a `CFBundleURLTypes` entry with `digia-engage` in `CFBundleURLSchemes` to `Info.plist`. Route
the link to the SDK:

```swift
.onOpenURL { url in
    guard Digia.isDebugSettingsDeepLink(url) else { return }
    _ = Digia.handleDeepLink(url, from: topViewController)
}
```

Get `topViewController` with the app's own helper. UIKit: call
`Digia.handleDeepLink(url, from:)` in `scene(_:openURLContexts:)`.

## Build

`xcodebuild -scheme <App> -sdk iphonesimulator -configuration Debug build` (add
`-workspace *.xcworkspace` with CocoaPods).

## Check

| ID | Rule | Severity | CEP | Detect | Fix |
|---|---|---|---|---|---|
| IO-01 | CEP plugin added, one core | fail | all | the CEP plugin URL or pod, and no separate core package, in `Package.swift`, `project.pbxproj` or `Podfile` | Add **Dependencies**. |
| IO-02 | Initialized at launch | fail | all | `try await Digia.initialize(` in the app launch code | Add **Initialize and register**. |
| IO-03 | Real API key | fail | all | `apiKey:` value is not `YOUR_API_KEY` | Put the key from the Digia dashboard. |
| IO-04 | One plugin registered, after `initialize` and the CEP SDK start | fail | all | exactly one `Digia.register(`, after `Digia.initialize(` and the CEP start call | Add the call from **Initialize and register**. |
| IO-05 | Host present | fail | all | exactly one `DigiaHost` | Add **Host**. |
| IO-06 | Screen tracking | fail | all | `Digia.setCurrentScreen(` or `digiaScreen(` | Add **Screen tracking**. |
| IO-07 | Identity | warn | all | `Digia.setUserId(` and `Digia.clearUserId(` | Add **Identity**. |
| IO-08 | Deployment target | warn | all | `IPHONEOS_DEPLOYMENT_TARGET` at 17.0 or above | Tell the user that devices below iOS 17 show no campaigns. |
| IO-09 | CleverTap native setup | fail | clevertap | `prepareCleverTapCustomTemplates()` before `CleverTap.autoIntegrate()`, `CleverTapAccountID` in `Info.plist` | Add the **CleverTap** step. |
| IO-10 | WebEngage delegate | fail | webengage | `notificationDelegate: DigiaWebEngagePlugin.notificationDelegate` | Add the **WebEngage** step. |
| IO-11 | Debug deeplink | warn | all | `digia-engage` in `CFBundleURLSchemes` and `Digia.handleDeepLink(` | Add **Debug deeplink**. |
