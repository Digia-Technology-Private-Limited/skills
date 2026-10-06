# iOS

Docs: `https://www.digia.tech/docs/developer/<cep>.md` (`clevertap`, `moengage`, `webengage`).
Read the install section for the package URLs and latest versions. Digia-managed campaigns are
not available on iOS yet: ask the user which CEP to use.

## Dependencies

| CEP | Swift package products |
|---|---|
| clevertap | `DigiaEngage` `DigiaEngageCleverTap` |
| moengage | `DigiaEngage` `DigiaMoEngage` |
| webengage | `DigiaEngage` `DigiaEngageWebEngage` |

Use Swift Package Manager, or CocoaPods if the project has a `Podfile`. The WebEngage plugin
brings the WebEngage SDK: remove a separate WebEngage package to avoid duplicate symbols.

Set the deployment target to iOS 17.0 or later. Below 17, the SDK does nothing.

## Initialize and register

At launch, on the main actor:

```swift
import DigiaEngage
import DigiaEngageCleverTap

Task { @MainActor in
    try await Digia.initialize(DigiaConfig(apiKey: "YOUR_API_KEY"))
    Digia.register(DigiaCleverTapPlugin())
}
```

| CEP | Register call |
|---|---|
| clevertap | `Digia.register(DigiaCleverTapPlugin())` |
| moengage | `Digia.register(MoEngagePlugin())` |
| webengage | `Digia.register(DigiaWebEngagePlugin())` |

`initialize` takes the config without a label. Register one plugin.

## CEP native steps

CleverTap, in `application(_:didFinishLaunchingWithOptions:)`:

```swift
DigiaCleverTapPlugin.prepareCleverTapCustomTemplates()
CleverTap.autoIntegrate()
```

MoEngage: start MoEngage as its docs say, before `Digia.initialize`.

WebEngage, in the app delegate launch hook (SwiftUI: `@UIApplicationDelegateAdaptor`):

```swift
WebEngage.sharedInstance().application(application,
    didFinishLaunchingWithOptions: launchOptions ?? [:],
    notificationDelegate: DigiaWebEngagePlugin.notificationDelegate,
    autoRegister: false)
```

## Host

SwiftUI: wrap the root view once.

```swift
WindowGroup { DigiaHost { ContentView() } }
```

UIKit: add a `UIHostingController(rootView: DigiaHost { EmptyView() })` as a child of the root
view controller, full size, with touches passed through to the content below.

## Screen tracking

SwiftUI: `.onAppear { Digia.setCurrentScreen(name: "home") }` on each screen's root view. UIKit:
`digiaScreen("home")` in `viewDidAppear`. The names must match the screen names in the Digia
dashboard, case included.

## Identity

Next to the app's login and logout code: `Digia.setUserId(user.id)`, then on logout
`Digia.clearUserId()` and `Digia.clearAllInlineContent()`. Keep the CEP's own login call.

## Debug deeplink

Add `digia-engage` to `CFBundleURLSchemes` in `Info.plist`. Route the URL to
`Digia.handleDeepLink(url, from: presenter)`, with the top view controller as `presenter`. It
returns `false` for other URLs.

- SwiftUI: in `.onOpenURL`, when `Digia.isDebugSettingsDeepLink(url)` is true.
- UIKit: in `scene(_:openURLContexts:)`.

## Build

`xcodebuild -scheme <App> -sdk iphonesimulator -configuration Debug build`

## v1 upgrade

| v1 | v2 |
|---|---|
| `DigiaCEPDelegate`, `setup(delegate:)`, `healthCheck`, `teardown` | Use the published plugin class. |
| `Digia.initialize(config: ...)` | `Digia.initialize(...)` without a label |
| `Digia.setCurrentScreen("x")`, `forwardScreen` | `Digia.setCurrentScreen(name: "x")` |
| `registerPlaceholder` | `DigiaSlot("key")` |
