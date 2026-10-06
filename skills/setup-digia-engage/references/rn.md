# React Native

Docs: `https://www.digia.tech/docs/developer/<cep>.md` (`clevertap`, `moengage`, `webengage`,
`digia-cep`). Read the install section for the latest package versions.

## Dependencies

| CEP | Packages |
|---|---|
| clevertap | `@digia-engage/core` `@digia-engage/clevertap` |
| moengage | `@digia-engage/core` `@digia-engage/moengage` |
| webengage | `@digia-engage/core` `@digia-engage/webengage` |
| digia | `@digia-engage/core` |

Install with the app's package manager (the lockfile tells you which). Then run `pod install`
in `ios/`. The packages autolink. Keep the app's own CEP SDK (`clevertap-react-native`,
`react-native-moengage`, `react-native-webengage`).

Expo: the packages have no config plugin. The app needs a development build. If there is no
`ios/` or `android/` folder, run `npx expo prebuild`. Put native edits in a config plugin when the
app already uses them for native code, so the next prebuild keeps them.

## Initialize and register

Put this in the startup code that runs once, before the first screen needs campaigns. Await both
calls: an early campaign is dropped as `not_ready`.

```ts
import { Digia } from '@digia-engage/core';
import { DigiaCleverTapPlugin } from '@digia-engage/clevertap';

await Digia.initialize({ apiKey: 'YOUR_API_KEY' });
await Digia.register(new DigiaCleverTapPlugin());
```

| CEP | Second call |
|---|---|
| clevertap | `await Digia.register(new DigiaCleverTapPlugin())` from `@digia-engage/clevertap` |
| moengage | `await Digia.register(new DigiaMoEngagePlugin())` from `@digia-engage/moengage` |
| webengage | `await Digia.register(new DigiaWebEngagePlugin())` from `@digia-engage/webengage` |
| digia | `Digia.enableManagedCampaigns()` |

The plugin constructors take no arguments.

## Host

Render `<DigiaHost />` once, as the last child of the root component, after the navigator:

```tsx
<NavigationContainer>{/* app */}</NavigationContainer>
<DigiaHost />
```

Expo Router: `<Stack />` then `<DigiaHost />` in the root `_layout`.

The SDK mounts the native overlay host itself during `initialize`. Use only `<DigiaHost />` in
JavaScript.

## Screen tracking

Report each screen when it gains focus. The names must match the screen names in the Digia
dashboard, case included.

```ts
useFocusEffect(useCallback(() => { Digia.setCurrentScreen('home'); }, []));
```

Or once, on the container:

```tsx
<NavigationContainer ref={navigationRef} onStateChange={() => {
  const name = navigationRef.getCurrentRoute()?.name;
  if (name) Digia.setCurrentScreen(name);
}}>
```

## Identity

Next to the app's existing login and logout code:

```ts
await Digia.setUserId(user.id);   // login
Digia.clearUserId();              // logout
Digia.clearAllInlineContent();    // logout
```

Keep the CEP's own login call. It does not reach Digia.

## CEP native steps

### CleverTap

Android `MainApplication.onCreate`, in this order:

```kotlin
DigiaCleverTapPlugin.prepareCleverTapCustomTemplates() // com.digia.engage.clevertap
ActivityLifecycleCallback.register(this)
super.onCreate()
CleverTapRnAPI.initReactNativeIntegration(this)
```

iOS `AppDelegate`, in `didFinishLaunchingWithOptions` before the `return`:

```swift
import DigiaEngageCleverTap

DigiaCleverTapPlugin.prepareCleverTapCustomTemplates()
CleverTap.autoIntegrate()
CleverTapReactManager.sharedInstance()?.applicationDidLaunch(options: launchOptions)
```

Without the template call, CleverTap drops every Digia campaign. Remove any `digia.json` template
file: the template is now registered in code.

### MoEngage

Use the normal MoEngage React Native setup. No Digia native step.

### WebEngage

iOS `AppDelegate` starts WebEngage with the Digia delegate. WebEngage accepts one delegate, at
start only:

```swift
import DigiaEngageWebEngage

WebEngage.sharedInstance().application(application,
  didFinishLaunchingWithOptions: launchOptions,
  webengageConfig: WebEngageConfig.builder()
    .setNotificationDelegate(DigiaWebEngagePlugin.notificationDelegate)
    .build())
```

Android `MainApplication.onCreate`:

```kotlin
registerActivityLifecycleCallbacks(
  WebEngageActivityLifeCycleCallbacks(this, WebEngageConfig.Builder().build()))
```

### Digia

No CEP SDK. Every campaign needs screen tracking for its on-screen trigger.

## Debug deeplink

iOS: add `digia-engage` to `CFBundleURLSchemes` in `Info.plist` (Expo: `expo.ios.infoPlist`).
The `AppDelegate` `open url` method gives React Native the URL first:

```swift
let handledByReactNative = RCTLinkingManager.application(app, open: url, options: options)
return OtherSDK.application(app, open: url, options: options) || handledByReactNative
```

Android needs no step.

## Build

- Android: `cd android && ./gradlew assembleDebug`
- iOS: `cd ios && pod install && xcodebuild -workspace *.xcworkspace -scheme <App> -sdk iphonesimulator -configuration Debug build`
- TypeScript: `npx tsc --noEmit`

## v1 upgrade

| v1 | v2 |
|---|---|
| `projectId`, `baseUrl` in config | `apiKey` only |
| `createCleverTapClient(...)`, `new DigiaCleverTapPlugin({ cleverTap })` | `new DigiaCleverTapPlugin()` |
| `WebEngageBridge` | `new DigiaWebEngagePlugin()` |
| `Digia.register(plugin)` without `await` | `await Digia.register(plugin)` |
| `<DigiaHostView>` | `<DigiaHost />` |
| `Digia.onCampaignTriggered`, `Digia.registerAnchor` | remove; use `<DigiaAnchorView anchorKey>` |
| `digia.json` CleverTap template | `prepareCleverTapCustomTemplates()` |
