# React Native

Docs: `https://www.digia.tech/docs/developer/<cep>` (`clevertap`, `moengage`, `webengage`,
`digia-cep`). Get the latest versions with `npm view <package> version`, except for these pins:

- `clevertap-react-native@4.3.1`, exact (`npm install --save-exact`). Version 4.4.0 changed a native method. With it, no
  Digia campaign shows.
- `react-native-moengage@^12.5.0`. The MoEngage plugin does not accept version 13.
- `react-native-webengage@^1.6.2`. The WebEngage plugin does not accept version 2.

## Dependencies

| CEP | Packages |
|---|---|
| clevertap | `@digia-engage/core` `@digia-engage/clevertap` `clevertap-react-native` |
| moengage | `@digia-engage/core` `@digia-engage/moengage` `react-native-moengage` |
| webengage | `@digia-engage/core` `@digia-engage/webengage` `react-native-webengage` |
| digia | `@digia-engage/core` |

Install with the app's package manager (the lockfile tells you which). Keep the app's CEP SDK if
it is already there.

Also install `react-native-svg` and `@react-native-async-storage/async-storage`. They autolink
only when they are in the app's `package.json`.

iOS: run `pod install` in `ios/`. Xcode 27 rejects pod targets below iOS 15.0. Add this inside
the Podfile's `post_install`, after `react_native_post_install(...)`:

```ruby
installer.pods_project.targets.each do |target|
  target.build_configurations.each do |bc|
    if bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.1
      bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = min_ios_version_supported
    end
  end
end
```

Expo: the packages have no config plugin. The app needs a development build. If there is no
`ios/` or `android/` folder, run `npx expo prebuild`. Put native edits in a config plugin when the
app already uses them for native code, so the next prebuild keeps them.

## Initialize and register

Put this in the app's startup code. With no such place, use a `useEffect(() => { ... }, [])` in
the root `App` component. Await `initialize` before `register`.

```ts
import { Digia } from '@digia-engage/core';
import CleverTap from 'clevertap-react-native';
import { DigiaCleverTapPlugin, createCleverTapClient } from '@digia-engage/clevertap';

await Digia.initialize({ apiKey: 'YOUR_API_KEY' });
Digia.register(new DigiaCleverTapPlugin({ cleverTap: createCleverTapClient(CleverTap) }));
```

A sandbox API key also needs `environment: 'sandbox'` in the `initialize` config.

| CEP | Second call |
|---|---|
| clevertap | `Digia.register(new DigiaCleverTapPlugin({ cleverTap: createCleverTapClient(CleverTap) }))` |
| moengage | `Digia.register(new DigiaMoEngagePlugin({ moEngage: ReactMoE }))`, with `import ReactMoE from 'react-native-moengage'` and `DigiaMoEngagePlugin` from `@digia-engage/moengage` |
| webengage | `Digia.register(new DigiaWebEngagePlugin())` from `@digia-engage/webengage` |
| digia | `Digia.enableManagedCampaigns()` |

Register one plugin. With `digia`, register no plugin.

## Host

Render `<DigiaHost />` once, as the last child of the root component, after the navigator:

```tsx
<NavigationContainer>{/* app */}</NavigationContainer>
<DigiaHost />
```

Expo Router: `<Stack />` then `<DigiaHost />` in the root `_layout`.

## Screen tracking

Report each screen when it gains focus. The names must match the screen names in the Digia
dashboard, case included.

```ts
useFocusEffect(useCallback(() => { Digia.setCurrentScreen('home'); }, []));
```

Or once, on the container:

```tsx
import { createNavigationContainerRef, ParamListBase } from '@react-navigation/native';

const navigationRef = createNavigationContainerRef<ParamListBase>();

<NavigationContainer ref={navigationRef} onStateChange={() => {
  const name = navigationRef.getCurrentRoute()?.name;
  if (name) Digia.setCurrentScreen(name);
}}>
```

With no navigation library, call `Digia.setCurrentScreen(name)` in a `useEffect` that runs when
the visible screen changes.

## Identity

Next to the app's existing login and logout code:

```ts
Digia.setUserId(user.id);         // login
Digia.clearUserId();              // logout
Digia.clearAllInlineContent();    // logout
```

Keep the CEP's own login call. It does not reach Digia.

## CEP native steps

### CleverTap

The package registers the Digia template itself. Follow the CleverTap React Native setup:

- Android `MainApplication.onCreate`: `ActivityLifecycleCallback.register(this)` before
  `super.onCreate()`, then `CleverTapRnAPI.initReactNativeIntegration(this)`.
- iOS `AppDelegate`, before React Native starts: `CleverTap.autoIntegrate()`, then
  `CleverTapReactManager.sharedInstance()?.applicationDidLaunch(options: launchOptions)`.
- Add the CleverTap account ID and token: `CLEVERTAP_ACCOUNT_ID` and `CLEVERTAP_TOKEN`
  `<meta-data>` in `AndroidManifest.xml`, and `CleverTapAccountID` and `CleverTapToken` in
  `Info.plist`. Ask the user for them. If they skip, write `YOUR_CLEVERTAP_ACCOUNT_ID` and
  `YOUR_CLEVERTAP_TOKEN`. If the account has a region (for example `in1`), also add
  `CLEVERTAP_REGION` and `CleverTapRegion`.
- iOS `Podfile`: add `pod 'SDWebImage', :modular_headers => true`. The CleverTap pod needs it.

### MoEngage

Call `ReactMoE.initialize('YOUR_MOENGAGE_APP_ID')` before `Digia.register`. Keep the native
MoEngage setup from the `react-native-moengage` docs. If the app does not have it, add:

- Android `MainApplication.onCreate`, after `super.onCreate()` and before React Native loads:
  `MoEInitializer.initializeDefaultInstance(applicationContext, MoEngage.Builder(this, "YOUR_MOENGAGE_APP_ID", DataCenter.DATA_CENTER_1))`.
  Use the account's data center.
- Android app module: `implementation(platform("com.moengage:plugin-base-bom:3.1.0"))`. Without
  it, Gradle cannot find `plugin-base`. Also add `com.github.bumptech.glide:glide:4.16.0`.
  Without Glide, MoEngage stops the app when an in-app campaign with an image arrives.
- iOS `AppDelegate`, before React Native starts:
  `MoEngageInitializer.sharedInstance().initializeDefaultSDKConfig(MoEngageSDKConfig(appId: "YOUR_MOENGAGE_APP_ID", dataCenter: .data_center_01), andLaunchOptions: launchOptions ?? [:])`.
  Use the account's data center.

### WebEngage

iOS `AppDelegate`: start WebEngage with the Digia delegate. WebEngage accepts one delegate, at
start only:

```swift
import DigiaWebEngage

WebEngage.sharedInstance().application(application,
  didFinishLaunchingWithOptions: launchOptions,
  notificationDelegate: WEDigiaSuppressProxy.shared())
```

The iOS pod needs iOS 17.0. Android needs no Digia step.

### Digia

No CEP SDK. Every campaign needs screen tracking for its on-screen trigger.

## Debug deeplink

iOS: add a `CFBundleURLTypes` entry with `digia-engage` in `CFBundleURLSchemes` to `Info.plist`
(Expo: `expo.ios.infoPlist`). If `AppDelegate` has no `application(_:open:options:)`, add it and
return `RCTLinkingManager.application(app, open: url, options: options)`.

If the app handles incoming URLs in JavaScript, pass the Digia link on first:

```ts
if (Digia.isDebugSettingsDeepLink(url)) { Digia.handleDeepLink(url); return; }
```

## Build

- Android: `cd android && ./gradlew assembleDebug`. Add `-PreactNativeArchitectures=arm64-v8a`
  for a faster check build.
- iOS: `cd ios && pod install && xcodebuild -workspace *.xcworkspace -scheme <App> -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- TypeScript: `npx tsc --noEmit`

## Check

| ID | Rule | Severity | CEP | Detect | Fix |
|---|---|---|---|---|---|
| RN-01 | Core package installed | fail | all | `@digia-engage/core` in `package.json` | Install it. |
| RN-02 | CEP plugin and CEP SDK installed | fail | clevertap, moengage, webengage | both packages from **Dependencies** in `package.json` | Install the pair. |
| RN-03 | `initialize` is awaited before `register` | fail | all | `await Digia.initialize(` before `Digia.register(` or `enableManagedCampaigns(` | Move the call after the awaited `initialize`. |
| RN-04 | Real API key | fail | all | `apiKey:` value is not `YOUR_API_KEY` | Put the key from the Digia dashboard. |
| RN-05 | One `<DigiaHost />`, last child of the root | fail | all | exactly one `<DigiaHost` in the source | Add it after the navigator. |
| RN-06 | One plugin registered, or managed campaigns on | fail | all | one `Digia.register(`; for `digia`, `Digia.enableManagedCampaigns()` and no `register` | Add the call from **Initialize and register**. |
| RN-07 | Screen tracking | fail | all | `Digia.setCurrentScreen(` | Add **Screen tracking**. |
| RN-08 | Identity | warn | all | `Digia.setUserId(` and `Digia.clearUserId(` | Add **Identity**. |
| RN-10 | CleverTap native setup | fail | clevertap | `ActivityLifecycleCallback.register` in `MainApplication`, `CleverTap.autoIntegrate` in `AppDelegate`, account ID on both platforms | Add the **CleverTap** steps. |
| RN-11 | MoEngage started | fail | moengage | `ReactMoE.initialize(` | Add the **MoEngage** step. |
| RN-12 | WebEngage iOS delegate | fail | webengage | `WEDigiaSuppressProxy.shared()` in `AppDelegate` | Add the **WebEngage** step. |
| RN-13 | iOS debug deeplink scheme | warn | all | `digia-engage` in `CFBundleURLSchemes` | Add **Debug deeplink**. |
| RN-14 | CleverTap pin | fail | clevertap | `clevertap-react-native` is `4.3.1` in `package.json` | Install `clevertap-react-native@4.3.1`. |
| RN-15 | MoEngage Glide | warn | moengage | `com.github.bumptech.glide:glide` in `android/app/build.gradle(.kts)` | Add Glide from the **MoEngage** step. |
| RN-16 | MoEngage SDK version | fail | moengage | `react-native-moengage` is `^12.5.0` or a later 12.x in `package.json` | Install `react-native-moengage@^12.5.0`. |
| RN-17 | WebEngage SDK version | fail | webengage | `react-native-webengage` is `^1.6.2` or a later 1.x in `package.json` | Install `react-native-webengage@^1.6.2`. |
