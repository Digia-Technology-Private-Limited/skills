# React Native

Docs: `https://www.digia.tech/docs/developer/<setup>`: `digia-cep` for `digia`, `clevertap`,
`moengage` or `webengage`. For `dmc`, follow the CEP's page, plus the events and user attributes
from `digia-cep`.
Get the latest versions with `npm view <package> version`. `@digia-engage/core` must be 3.4.0 or
later. The app needs React Native 0.83+ and React 19.2+.

## Dependencies

| CEP | Packages |
|---|---|
| clevertap | `@digia-engage/core` `@digia-engage/clevertap` `clevertap-react-native` |
| moengage | `@digia-engage/core` `@digia-engage/moengage` `react-native-moengage` |
| webengage | `@digia-engage/core` `@digia-engage/webengage` `react-native-webengage` |
| digia | `@digia-engage/core` |

`dmc` uses its CEP's packages.

Install with the app's package manager (the lockfile tells you which). Keep the app's CEP SDK if
it is already there.

Also install `react-native-svg` and `@react-native-async-storage/async-storage`. They autolink
only when they are in the app's `package.json`.
Do not change the version of a package that the app already has. If the app's version differs
from the one Digia asks for, npm can install two copies, and native modules break without an
install error. Tell the user, and point them to
`https://www.digia.tech/docs/developer/reference/dependency-conflicts` for the `overrides` or
`resolutions` fix. Add an override only with consent.

iOS: new Digia pod versions are published to the Digia spec repo, not CocoaPods trunk. React
Native CLI: add these two lines at the very top of `ios/Podfile`. Keep the CDN line, or every other
pod stops resolving:

```ruby
source 'https://github.com/Digia-Technology-Private-Limited/digia-podspecs.git'
source 'https://cdn.cocoapods.org/'
```

Then run `pod install --repo-update` in `ios/`. If `pod install` says "None of your spec sources
contain a spec satisfying the dependency: DigiaEngage", the `source` line is missing. When you
upgrade `@digia-engage/core`, do a clean install:
`rm -rf node_modules ios/Pods ios/build && <install> && cd ios && pod install --repo-update`.
Keep `Podfile.lock` and commit the updated one. `SPEC REPOS` in it lists `digia-podspecs`. If CI
caches `Pods/` or DerivedData, tell the user to clear that cache once. Android needs no change.
Details: `https://www.digia.tech/docs/developer/reference/ios-spec-repo/`.

Expo: add `"plugins": ["@digia-engage/core"]` to `app.json` (keep the app's other plugins). It
adds the spec repo lines to the Podfile at prebuild. The app needs a development build. Run
`npx expo prebuild --clean --platform ios`, then `cd ios && pod install --repo-update`. If there is
no `android/` folder, also run `npx expo prebuild`. Put other native edits in a config plugin when
the app already uses them for native code, so the next prebuild keeps them.

## Initialize and register

Put this in the app's startup code, once. With no such place, use a `useEffect` in the root
component. Start the CEP first, then register the plugin, then initialize Digia:

```tsx
import { useEffect } from 'react';
import CleverTap from 'clevertap-react-native';
import { Digia } from '@digia-engage/core';
import { DigiaCleverTapPlugin, createCleverTapClient } from '@digia-engage/clevertap';

useEffect(() => {
  (async () => {
    await Digia.register(new DigiaCleverTapPlugin({ cleverTap: createCleverTapClient(CleverTap) }));
    await Digia.initialize({ apiKey: 'digia_xxx' });
  })().catch(console.error);
}, []);
```

With `digia`, call only `Digia.initialize({ apiKey: 'digia_xxx' }).catch(console.error);`.

`initialize` returns once campaigns load, or after 2 seconds. Awaiting it delays startup by up to
2 seconds. To not wait, call it without `await` and keep `.catch(console.error)`. Events sent
before it finishes are held for up to 10 seconds and replayed.

Optional config fields:

- `environment: 'sandbox'` for a sandbox API key. The default is `'production'`.
- `logLevel: 'none' | 'error' | 'verbose'`. Only errors are logged by default.
- `actionHandlers: { customKV, deepLink, openURL }` to handle campaign actions in app code.

| CEP | Register call |
|---|---|
| clevertap | `await Digia.register(new DigiaCleverTapPlugin({ cleverTap: createCleverTapClient(CleverTap) }))` |
| moengage | `await Digia.register(new DigiaMoEngagePlugin({ moEngage: ReactMoE }))`, with `import ReactMoE from 'react-native-moengage'` and `DigiaMoEngagePlugin` from `@digia-engage/moengage` |
| webengage | `await Digia.register(new DigiaWebEngagePlugin())` from `@digia-engage/webengage` |

Register one plugin. With `dmc`, register its CEP's plugin. With `digia`, register no plugin.

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

## Anchors and slots

An anchor marks the view that a tooltip or spotlight points at. A slot shows inline content
(banner, card, story). Import both from
`@digia-engage/core`.

Anchors: by default, wrap the icon of each bottom tab. Make the key from the tab name, in
snake_case. Wrap everything `tabBarIcon` returns, so the focused and unfocused icons share one
anchor. React Navigation:

```tsx
options={{
  tabBarIcon: ({ focused, color, size }) => (
    <DigiaAnchorView anchorKey="nav_home">
      <Icon name={focused ? 'home' : 'home-outline'} color={color} size={size} />
    </DigiaAnchorView>
  ),
}}
```

A custom tab bar: wrap each tab button the same way.

Slots: add them yourself, one per screen, on the home screen and on each screen with static
content, for example offers, profile, about, terms, FAQ or order success. Name the key after the
screen, in snake_case: `home_top`, `about_top`. Put the slot at the top of the screen's content,
below the header. A slot takes no space when no campaign is live:

```tsx
<ScrollView>
  {/* Digia Engage: shows inline campaigns here. Takes no space when none is live. */}
  <DigiaSlotView placementKey="about_top" />
  <Text>{aboutText}</Text>
</ScrollView>
```

Ask the user before you add a slot inside a list, a grid or a form.

Give the user the list of keys. The marketer selects the same keys in the Digia dashboard.

## Identity

Next to the app's existing login and logout code:

```ts
Digia.setUserId(user.id);   // login
Digia.clearUserId();        // logout
```

Call `setUserId` after every login and on app start when a user is already logged in. Keep the
CEP's own login call. It does not reach Digia.

### User hash

Optional. Add it when the team connects data or turns on **Settings → User verification** in the
Digia Engage Dashboard. The app's backend computes the hash. Pass it with the user ID:

```ts
Digia.setUserId(user.id, userHash);
```

## More options

If the app shows its own popups, onboarding or a payment flow, hold Digia campaigns while it does:

```ts
Digia.setCampaignsSuppressed(true);   // before the app's own flow
Digia.setCampaignsSuppressed(false);  // after it
```

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

### MoEngage

Call `ReactMoE.initialize('YOUR_MOENGAGE_WORKSPACE_ID')` before `Digia.register`. Keep the native
MoEngage setup from the `react-native-moengage` docs. If the app does not have it, add:

- Android `MainApplication.onCreate`, after `super.onCreate()` and before React Native loads:
  `MoEInitializer.initializeDefaultInstance(applicationContext, MoEngage.Builder(this, "YOUR_MOENGAGE_APP_ID", DataCenter.DATA_CENTER_1))`.
  Use the account's data center.
- Android app module: add `com.github.bumptech.glide:glide:4.16.0`. Without Glide, MoEngage
  stops the app when an in-app campaign with an image arrives.
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

The iOS pod needs iOS 16.0. Android needs no Digia step.

### Digia

No CEP SDK. Add **Digia-managed campaigns**.

## Digia-managed campaigns

Only for `digia` and `dmc`. With only a CEP, do not add `trackEvent` or `setUserAttributes`: the
CEP receives the app's events and user data.

A campaign triggers on app open, app foreground, a screen view (from **Screen tracking**), an
anchor or slot becoming visible, or an event that the app sends. Add the events and user
attributes yourself. Do not ask the user which ones.

### Events

Send Digia the events the app already tracks, with the same names and properties, so the
marketer sees the same event names in their analytics tool and in the Digia dashboard:

1. The app has an analytics wrapper that every event goes through, for example a `track` helper
   around Firebase `logEvent`: add one `Digia.trackEvent` line inside it.
2. No wrapper: add `Digia.trackEvent` next to each direct analytics call, such as Firebase
   `logEvent`, Mixpanel `track`, Amplitude `track` or Segment `track`.
3. No analytics: add it at the app's key actions, such as sign up, login, search, add to cart,
   checkout and purchase. Use snake_case names, and pass the values already in scope.

```ts
export function track(name: string, params: Record<string, string | number | boolean> = {}) {
  analytics().logEvent(name, params);
  // Digia Engage: lets Digia-managed campaigns trigger on this event.
  Digia.trackEvent(name, params);
}
```

`trackEvent` takes the event name (1 to 120 characters) and properties only. Use string, number or
boolean values, or arrays of them: rules compare these. Put an amount in the properties, for
example `{ value: 650, currency: 'INR' }`. The event and property names appear in the dashboard
after the first event arrives.

### User attributes

Campaign conditions compare these:

1. The app sets user properties in its analytics tool, for example Firebase
   `setUserProperty(name, value)`: send the same name and value with `Digia.setUserAttributes`,
   next to each call or inside the wrapper.
2. Otherwise, right after `Digia.setUserId`, send the profile fields the app already has on the
   user, such as name, email, phone, city, plan and sign-up date.

```ts
Digia.setUserId(user.id);
// Digia Engage: campaign conditions can compare these attributes.
Digia.setUserAttributes({
  name: user.name,
  email: user.email,
  city: user.city,
  signup_date: user.createdAt.toISOString(),
});
```

Values are strings, numbers, booleans or string arrays. Send dates as ISO 8601 strings. Leave out
fields that are null or undefined. Calls merge. `setUserAttributes` needs `setUserId` first.
`Digia.clearUserId()` clears them.

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
| RN-01 | Core package installed | fail | all | `@digia-engage/core` 3.4.0 or later in `package.json` | Install or upgrade it. |
| RN-02 | CEP plugin and CEP SDK installed | fail | clevertap, moengage, webengage | both packages from **Dependencies** in `package.json` | Install the pair. |
| RN-03 | Plugin registered before `initialize` | fail | clevertap, moengage, webengage | `await Digia.register(` before `Digia.initialize(` | Move `register` before `initialize`, as **Initialize and register** says. |
| RN-04 | Real API key | fail | all | `apiKey:` value is not `digia_xxx` | Put the key from the Digia dashboard. |
| RN-05 | One `<DigiaHost />`, last child of the root | fail | all | exactly one `<DigiaHost` in the source | Add it after the navigator. |
| RN-06 | One plugin registered | fail | all | one `Digia.register(`; for `digia`, none | Add or remove the call as **Initialize and register** says. |
| RN-07 | Screen tracking | fail | all | `Digia.setCurrentScreen(` | Add **Screen tracking**. |
| RN-08 | Identity | warn | all | `Digia.setUserId(` and `Digia.clearUserId(` | Add **Identity**. |
| RN-10 | CleverTap native setup | fail | clevertap | `ActivityLifecycleCallback.register` in `MainApplication`, `CleverTap.autoIntegrate` in `AppDelegate`, account ID on both platforms | Add the **CleverTap** steps. |
| RN-11 | MoEngage started | fail | moengage | `ReactMoE.initialize(` | Add the **MoEngage** step. |
| RN-12 | WebEngage iOS delegate | fail | webengage | `WEDigiaSuppressProxy.shared()` in `AppDelegate` | Add the **WebEngage** step. |
| RN-13 | iOS debug deeplink scheme | warn | all | `digia-engage` in `CFBundleURLSchemes` | Add **Debug deeplink**. |
| RN-15 | MoEngage Glide | warn | moengage | `com.github.bumptech.glide:glide` in `android/app/build.gradle(.kts)` | Add Glide from the **MoEngage** step. |
| RN-18 | App events sent | fail | digia, dmc | `Digia.trackEvent(` in the analytics wrapper or next to each analytics event call; with no analytics, at least one | Add **Events**. |
| RN-19 | User attributes sent | warn | digia, dmc | `Digia.setUserAttributes(` | Add **User attributes**. |
| RN-20 | Selected tab anchored | warn | all | each `tabBarIcon` returns a `DigiaAnchorView` around both its focused and unfocused icon | Wrap the icon as **Anchors and slots** says. |
| RN-21 | Digia spec repo | fail | all | Expo: `@digia-engage/core` in `app.json` `plugins`; React Native CLI: `digia-podspecs.git` and `cdn.cocoapods.org` `source` lines at the top of `ios/Podfile` | Add the step from **Dependencies** and run `pod install --repo-update`. |
