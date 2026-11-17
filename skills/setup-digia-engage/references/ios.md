# iOS

Docs: `https://www.digia.tech/docs/developer/<setup>` (`digia-cep` for `digia`, `clevertap`,
`moengage`, `webengage`). For `dmc`, follow the CEP page, then the events and attributes from `digia-cep`.

## Dependencies

Add the core package, and with a CEP also its plugin package, with Swift Package Manager at
their latest tags. `dmc` uses the packages of its CEP.

| Package | URL | Product | When |
|---|---|---|---|
| Core | `https://github.com/Digia-Technology-Private-Limited/digia_engage_iOS.git` | `DigiaEngage` | always |
| CleverTap | `https://github.com/Digia-Technology-Private-Limited/digia_engage_clevertap_iOS.git` | `DigiaEngageCleverTap` | clevertap |
| MoEngage | `https://github.com/Digia-Technology-Private-Limited/de_ios_moengage.git` | `DigiaMoEngage` | moengage |
| WebEngage | `https://github.com/Digia-Technology-Private-Limited/de_ios_webengage.git` | `DigiaEngageWebEngage` | webengage |

Get the latest tag with `git ls-remote --tags <url>`. `DigiaEngage` must meet the floor in
[shared.md](shared.md#version-floors). Edit `Package.swift`, for example
`.package(url: "https://github.com/Digia-Technology-Private-Limited/digia_engage_iOS.git", from: "4.4.0")`,
or the Xcode project package references.

If the app has a `Podfile` and no SPM packages, use CocoaPods. New Digia pod versions are
published to the Digia spec repo, not CocoaPods trunk. Add the two `source` lines at the very top
of the `Podfile`. Keep the CDN line, or every other pod stops resolving:

```ruby
source 'https://github.com/Digia-Technology-Private-Limited/digia-podspecs.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'YourApp' do
  pod 'DigiaEngage', '~> 4.4'
  pod 'DigiaEngageCleverTap' # with CleverTap; DigiaMoEngage with MoEngage; DigiaEngageWebEngage with WebEngage
end
```

Then run `pod install --repo-update`. Keep `Podfile.lock` and commit the updated one. If CI caches
`Pods/` or DerivedData, tell the user to clear that cache once. Details:
`https://www.digia.tech/docs/developer/reference/ios-spec-repo/`.

Set the deployment target as [shared.md](shared.md#version-floors) says, and tell the user if it is
below 17.0.

## Initialize and register

In the app's launch code (`App.init` with SwiftUI, or `application(_:didFinishLaunchingWithOptions:)`):
start the CEP SDK, register the plugin, then initialize, in the order in
[shared.md](shared.md#call-order).

```swift
import CleverTapSDK
import DigiaEngage
import DigiaEngageCleverTap

DigiaCleverTapPlugin.prepareCleverTapCustomTemplates() // CleverTap only
CleverTap.autoIntegrate()                              // CleverTap only
Digia.register(DigiaCleverTapPlugin()) // not for digia
Task { try? await Digia.initialize(DigiaConfig(apiKey: "digia_xxx")) }
```

`initialize` returns as [shared.md](shared.md#held-before-ready) says. The `Task` above does not
block launch: the app starts at once and campaigns load in the background. To show campaigns
before the first screen instead, `try await Digia.initialize(...)` before you show it. Startup can
then take up to 2 seconds longer.

Optional `DigiaConfig` fields: `logLevel`, `actionHandlers` (handle deep links, web links and
Custom KV commands yourself), `themeMode` (`auto`, `light` or `dark`) and `fontFamily`. Add one
only when the user asks.

| CEP | Import | Register call |
|---|---|---|
| clevertap | `DigiaEngageCleverTap` | `Digia.register(DigiaCleverTapPlugin())` |
| moengage | `DigiaMoEngage` | `Digia.register(MoEngagePlugin())` |
| webengage | `DigiaEngageWebEngage` | `Digia.register(DigiaWebEngagePlugin())` |

Start the CEP SDK before `register`. Register one plugin. With `dmc`, register the plugin of its
CEP. With `digia`, register no plugin and import only `DigiaEngage`.

## CEP native steps

- CleverTap: call `DigiaCleverTapPlugin.prepareCleverTapCustomTemplates()` before
  `CleverTap.autoIntegrate()`, and both before `register`. The first call registers the Digia
  template, which CleverTap accepts only before it starts. Add `CleverTapAccountID` and
  `CleverTapToken` to `Info.plist`. Ask the user for them. If they skip, write `YOUR_CLEVERTAP_ACCOUNT_ID` and
  `YOUR_CLEVERTAP_TOKEN`. If the account has a region (for example `in1`), also add
  `CleverTapRegion`.
- MoEngage: start MoEngage with `MoEngage.sharedInstance.initializeDefaultInstance(...)` as its
  docs say, before `register`.
- WebEngage: in `application(_:didFinishLaunchingWithOptions:)`, pass the plugin's delegate to
  WebEngage. Without it, WebEngage renders Digia campaigns itself. SwiftUI apps need an
  `AppDelegate` through `@UIApplicationDelegateAdaptor`. Register right after, in the same method:
  an in-app that arrives before `register` is dropped.

  ```swift
  import WebEngage
  import DigiaEngage
  import DigiaEngageWebEngage

  WebEngage.sharedInstance().application(
      application,
      didFinishLaunchingWithOptions: launchOptions,
      notificationDelegate: DigiaWebEngagePlugin.notificationDelegate
  )
  Digia.register(DigiaWebEngagePlugin())
  ```

  Add the plugin with the same tool that brings the app's WebEngage, or the build fails with
  duplicate symbols. The Swift package brings `webengage-ios-sdk` 2.x itself: add no other
  WebEngage. The pod needs `WebEngage` 7.0.4 or later, below 7.2.0. If the app pins another
  WebEngage, tell the user and follow the docs' dependency-conflicts page, with their consent.

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

## Anchors and slots

An anchor marks the view that a tooltip or spotlight points at. A slot shows inline content
(banner, card, story).

Anchors: by default, wrap each item of the app's custom bottom tab bar. Make the key from the item
label, in snake_case. Wrap the whole button, so the selected and normal states share one anchor.
If the button switches between two separate views, wrap each with the same key:

```swift
DigiaAnchor(anchorKey: "nav_home") {
    TabButton(icon: selected == .home ? "house.fill" : "house", title: "Home")
}
```

A system `TabView` or `UITabBar` draws its items in UIKit, so they cannot be wrapped: tell the
user, and propose anchors on the main buttons instead. UIKit: put the target view inside a
`DigiaAnchorView` with `anchorKey`, as its first subview.

Slots: add them yourself, one per screen, on the home screen and on each screen with static
content, for example offers, profile, about, terms, FAQ or order success. Name the key after the
screen, in snake_case: `home_top`, `about_top`. Put the slot at the top of the screen's content,
below the navigation bar or header. A slot takes no space when no campaign is live:

```swift
ScrollView {
    VStack(alignment: .leading) {
        // Digia Engage: shows inline campaigns here. Takes no space when none is live.
        DigiaSlot("about_top")
        Text(aboutText)
    }
}
```

UIKit: host it with `UIHostingController` at the top of the screen's content. Ask the user before
you add a slot inside a list, a grid or a form.

Give the user the list of keys. The marketer selects the same keys in the Digia dashboard.

## Identity

Next to the app's login and logout code: `Digia.setUserId(user.id)` after login, and
`Digia.clearUserId()` on logout. Keep the CEP's own login call. The user ID is remembered across
launches. Logout clears everything about the previous user, inline content included.

### User hash

Only if the team connects data (PostHog, Segment, Google Analytics) or turns on **Settings → User
verification** in the Digia Engage Dashboard. Otherwise skip it. The app's server signs the user
ID with the secret from **Settings → User verification** (HMAC-SHA256, as lowercase hex) and sends
it to the app, for example in the login response. Never put the secret in the app. Pass it with
the user ID:

```swift
Digia.setUserId(user.id, userHash: userHash)
```

If the server does not send a hash yet, tell the user. Do not compute it in the app.

## More options

If the app shows its own popup or a payment flow, stop campaigns from covering it:

```swift
Digia.setCampaignsSuppressed(true)   // the app's popup opens
Digia.setCampaignsSuppressed(false)  // …and closes
```

While it is on, new popups are skipped, not saved for later. Inline content keeps showing. Add it
only where the app has such a popup or flow.

## Digia-managed campaigns

Only for `digia` and `dmc`. With only a CEP, do not add `trackEvent` or `setUserAttributes`: the
CEP receives the app's events and user data.

A campaign triggers on app open, app foreground, a screen view (from **Screen tracking**), an
anchor or slot becoming visible, or an event that the app sends. Add the events and user
attributes yourself. Do not ask the user which ones.

### Events

Send Digia the events the app already tracks, with the same names and properties, so the
marketer sees the same event names in their analytics tool and in the Digia dashboard:

1. The app has an analytics wrapper that every event goes through, for example an
   `AnalyticsService.log` around `Analytics.logEvent`: add one `Digia.trackEvent` line inside it.
2. No wrapper: add `Digia.trackEvent` next to each direct analytics call, such as Firebase
   `Analytics.logEvent`, Mixpanel `track` or Amplitude `track`.
3. No analytics: add it at the app's key actions, such as sign up, login, search, add to cart,
   checkout and purchase. Use snake_case names, and pass the values already in scope.

```swift
func log(_ name: String, parameters: [String: Any] = [:]) {
    Analytics.logEvent(name, parameters: parameters)
    // Digia Engage: lets Digia-managed campaigns trigger on this event.
    Digia.trackEvent(name: name, properties: parameters)
}
```

`trackEvent` takes the event name (1 to 120 characters) and `properties` only. Use `String`,
number or `Bool` values, or arrays of them: rules compare these. Put an amount in `properties`,
for example `["value": 650, "currency": "INR"]`. The event and property names appear in the
dashboard after the first event arrives.

### User attributes

Campaign conditions compare these:

1. The app sets user properties in its analytics tool, for example
   `Analytics.setUserProperty(value, forName: name)`: send the same name and value with
   `Digia.setUserAttributes`, next to each call or inside the wrapper.
2. Otherwise, right after `Digia.setUserId`, send the profile fields the app already has on the
   user, such as name, email, phone, city, plan and sign-up date.

```swift
Digia.setUserId(user.id)
// Digia Engage: campaign conditions can compare these attributes.
Digia.setUserAttributes([
    "name": user.name,
    "email": user.email,
    "city": user.city,
    "signup_date": ISO8601DateFormatter().string(from: user.createdAt),
])
```

Values are `String`, number, `Bool` or `[String]`. Send dates as ISO 8601 strings. Leave out
fields that are nil. Calls merge. `setUserAttributes` needs `setUserId` first.
`Digia.clearUserId()` clears them.

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
| IO-01 | Core and CEP plugin added | fail | all | in `Package.swift`, `project.pbxproj` or `Podfile`: the `DigiaEngage` core at 4.4.0 or later, and the CEP plugin package or pod unless the CEP is `digia` | Add **Dependencies**. |
| IO-02 | Initialized at launch | fail | all | `Digia.initialize(` in the app launch code | Add **Initialize and register**. |
| IO-03 | Real API key | fail | all | `apiKey:` value is not `digia_xxx` | Put the key from the Digia dashboard. |
| IO-04 | One plugin registered, after the CEP SDK start | fail | clevertap, moengage, webengage | exactly one `Digia.register(`, after the CEP start call, either side of `Digia.initialize(` | Add the call from **Initialize and register**. |
| IO-05 | Host present | fail | all | exactly one `DigiaHost` | Add **Host**. |
| IO-06 | Screen tracking | fail | all | `Digia.setCurrentScreen(` or `digiaScreen(` | Add **Screen tracking**. |
| IO-07 | Identity | warn | all | `Digia.setUserId(` and `Digia.clearUserId(` | Add **Identity**. |
| IO-08 | Deployment target | warn | all | `IPHONEOS_DEPLOYMENT_TARGET` at 17.0 or above; it must be at least 15.0, or the build fails | Raise it to the minimum, and tell the user that devices below iOS 17 show no campaigns. |
| IO-09 | CleverTap native setup | fail | clevertap | `DigiaCleverTapPlugin.prepareCleverTapCustomTemplates()` before `CleverTap.autoIntegrate()`, both before `Digia.register(`; `CleverTapAccountID` in `Info.plist` | Add the **CleverTap** step. |
| IO-11 | Debug deeplink | warn | all | `digia-engage` in `CFBundleURLSchemes` and `Digia.handleDeepLink(` | Add **Debug deeplink**. |
| IO-12 | No stray plugin | fail | digia | no `Digia.register(` | Remove the call, or ask the user which CEP to use. |
| IO-13 | App events sent | fail | digia, dmc | `Digia.trackEvent(` in the analytics wrapper or next to each analytics event call; with no analytics, at least one | Add **Events**. |
| IO-14 | User attributes sent | warn | digia, dmc | `Digia.setUserAttributes(` | Add **User attributes**. |
| IO-15 | Selected tab anchored | warn | all | each custom tab button wrapped in `DigiaAnchor` keeps one anchor key for its selected and normal states | Wrap the button as **Anchors and slots** says. |
| IO-16 | Digia spec repo | fail | all | with a `Podfile`: `digia-podspecs.git` and `cdn.cocoapods.org` `source` lines at its top | Add the lines from **Dependencies** and run `pod install --repo-update`. |
| IO-17 | WebEngage delegate passed | fail | webengage | `notificationDelegate: DigiaWebEngagePlugin.notificationDelegate` in the WebEngage `didFinishLaunchingWithOptions` call | Add the **WebEngage** step. |
| IO-18 | WebEngage plugin registered early | warn | webengage | `Digia.register(DigiaWebEngagePlugin())` in the same launch method as the WebEngage start, right after it | Move the call as the **WebEngage** step says. |
