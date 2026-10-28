# Flutter

Docs: `https://www.digia.tech/docs/developer/<cep>` (`clevertap`, `moengage`, `webengage`).
With no CEP, use Digia-managed campaigns (`digia`): Digia decides on the device when a campaign
shows. Campaigns that Digia decides also show in an app that registers a CEP plugin.

## Dependencies

| CEP | Command |
|---|---|
| digia | `flutter pub add digia_engage:^2.2.0` |
| clevertap | `flutter pub add digia_engage:^2.2.0 digia_engage_clevertap:^2.0.0 clevertap_plugin:^3.8.1` |
| moengage | `flutter pub add digia_engage:^2.2.0 digia_moengage_plugin:^2.0.0 moengage_flutter:^10.5.0` |
| webengage | `flutter pub add digia_engage:^2.2.0 digia_webengage_plugin:^2.0.0 webengage_flutter:^1.7.0` |

If pub cannot find `digia_engage_clevertap` 2.0.0, stop and tell the user. Do not use 1.x: it
needs `digia_engage` 1.x.

Do not change the version of a package that is already in the app's `pubspec.yaml`. `digia_engage`
2.2.0 needs these major versions: `flutter_svg` 2, `share_plus` 11, `package_info_plus` 8,
`carousel_slider` 5, `lottie` 3, `uuid` 4, `connectivity_plus` 6 or 7, `sqflite` 2, and dio 5.9.1
or later. `connectivity_plus` adds the Android `ACCESS_NETWORK_STATE` permission. If `pub add` fails on one of them, it adds nothing. Then add the Digia lines to
`dependencies` by hand, and add a `dependency_overrides` entry with the version Digia needs, with
a comment:

```yaml
dependency_overrides:
  # Digia Engage needs flutter_svg 2. The app declares ^1.1.6.
  flutter_svg: ^2.0.17
```

App code that uses the old API can then fail, for example `precachePicture` in `flutter_svg` 1.
Do not change that code. Tell the user each override and each error it causes.

The SDK needs Dart 3.6 and Flutter 3.29 or later.

iOS: set the deployment target to 15.0 or later. Xcode 27 rejects the `flutter create`
default of 13.0. In `ios/Podfile`, set `platform :ios, '15.0'`, and set
`IPHONEOS_DEPLOYMENT_TARGET = 15.0` in `ios/Runner.xcodeproj/project.pbxproj`. If pods still
report 13.0, add this inside the Podfile's `post_install` loop, after
`flutter_additional_ios_build_settings(target)`:

```ruby
target.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
end
```

`flutter build ios` shows the deployment target error only as a warning. It then prints
"Encountered error while building for simulator".

Campaigns show from iOS 17.0.

If the app already has the CEP SDK, leave it out of the command, so its version stays. The Digia
plugins do not support the next major CEP SDK version (`clevertap_plugin` 4, `moengage_flutter` 11,
`webengage_flutter` 2). If the app uses one, tell the user that the plugin needs the range in the
command, and ask before you add an override for it.

Imports:

| CEP | Import |
|---|---|
| all | `package:digia_engage/digia_engage.dart` |
| clevertap | `package:digia_engage_clevertap/digia_engage_clevertap.dart` |
| moengage | `package:digia_moengage_plugin/digia_moengage_plugin.dart`, `package:moengage_flutter/moengage_flutter.dart` |
| webengage | `package:digia_webengage_plugin/digia_webengage_plugin.dart` |

## Initialize and register

In `main`, before `runApp`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Digia.initialize(DigiaConfig(apiKey: 'digia_xxx'));
  Digia.register(DigiaCleverTapPlugin());
  runApp(const MyApp());
}
```

| CEP | Register call |
|---|---|
| digia | none |
| clevertap | `Digia.register(DigiaCleverTapPlugin())` |
| moengage | `Digia.register(MoEngagePlugin(instance: moEngage))` |
| webengage | `Digia.register(DigiaWebEngagePlugin())` |

MoEngage: create the Dart `MoEngageFlutter` instance, call `initialise()`, and pass the same
instance to the plugin. You also start MoEngage natively (**CEP native steps**). Both are needed.

```dart
final moEngage = MoEngageFlutter('YOUR_MOENGAGE_APP_ID');
moEngage.initialise();
await Digia.initialize(DigiaConfig(apiKey: 'digia_xxx'));
Digia.register(MoEngagePlugin(instance: moEngage));
```

Register one plugin. A second `register` replaces the first. With `digia`, register no plugin.

## Host and screen tracking

```dart
MaterialApp(
  navigatorObservers: [DigiaNavigatorObserver()],
  builder: (context, child) => DigiaHost(child: child!),
)
```

The observer gives the SDK the app's navigator. Do not add a navigator key. If the app already
passes a `navigatorKey` to `MaterialApp`, also pass it: `DigiaHost(navigatorKey: navigatorKey, ...)`.

GoRouter: `GoRouter(observers: [DigiaNavigatorObserver()])` and `MaterialApp.router(builder: ...)`
with the same `DigiaHost`. Each `ShellRoute` needs its own observer. With shell routes, pass the
root navigator key to `DigiaHost` too, so the SDK shows nudges above the shell.

The observer reports `route.settings.name`. Give each route a `name`. For tabs in one route, call
`Digia.setCurrentScreen('tab_name')` on tab change. The names must match the screen names in the
Digia dashboard, case included.

Mount one `DigiaHost`. Two hosts show each nudge twice.

## Anchors and slots

An anchor marks the widget that a tooltip or spotlight points at. A slot shows inline content
(banner, card, story) and takes no space when no campaign is live.

Anchors: by default, wrap the icon of each bottom navigation item. Make the key from the item
label, in snake_case:

```dart
BottomNavigationBarItem(
  icon: DigiaAnchor(anchorKey: 'nav_home', child: const Icon(Icons.home)),
  label: 'Home',
)
```

Material 3: `NavigationDestination(icon: DigiaAnchor(anchorKey: 'nav_home', child: const Icon(Icons.home)), label: 'Home')`.

Slots: find the screens with static content, for example a home, offers or profile screen. Propose
one place on each, for example `DigiaSlot('home_banner')` below the header. Add a slot only when
the user agrees.

Give the user the list of keys. The marketer selects the same keys in the Digia dashboard.

## Identity

Next to the app's existing login and logout code:

```dart
await Digia.setUserId(user.id);   // login
await Digia.clearUserId();        // logout
Digia.clearAllInlineContent();    // logout
```

Keep the CEP's own login call. It does not reach Digia. MoEngage: `moEngage.identifyUser(user.id)`
on login, `moEngage.logout()` on logout.

Put the API key where the app keeps its other keys, for example `--dart-define`. If the app has no
such place, write it in `main`.

## Digia-managed campaigns

For `digia`, or when the user wants Digia-managed campaigns next to a CEP. A campaign triggers on
app open, on a screen view (from **Host and screen tracking**), or on an event that the app sends:

```dart
// Digia Engage: lets Digia-managed campaigns trigger on this event.
Digia.trackEvent('add_to_cart', properties: {'sku': sku, 'price': price});
// Revenue: Digia.trackEvent('order_placed', value: 650, currency: 'INR');
```

Ask the user which actions campaigns should trigger on, for example add to cart, purchase or search.
Add `trackEvent` at those places only. Use `String`, `num` or `bool` property values: rules compare these. The event and
property names appear in the dashboard after the first event arrives.

User attributes that campaign conditions compare, after `Digia.setUserId`:

```dart
// Digia Engage: campaign conditions can compare these attributes.
await Digia.setUserAttributes({'city': user.city, 'plan': user.plan});
```

Values are `String`, `num`, `bool` or `List<String>`. Calls merge. `Digia.clearUserId()` clears them.
Do not send personal data such as email or phone unless the user asks.

## CEP native steps

### CleverTap

The Digia template registers itself on both platforms. Android still needs a custom `Application`
class: create `MainApplication.kt` next to `MainActivity.kt`, in the same package, and set
`android:name=".MainApplication"` on `<application>`:

```kotlin
import com.clevertap.android.sdk.ActivityLifecycleCallback
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        ActivityLifecycleCallback.register(this)
        super.onCreate()
    }
}
```

iOS `AppDelegate`, in `didFinishLaunchingWithOptions` before `return super.application(...)`.
Import `CleverTapSDK`:

```swift
CleverTap.autoIntegrate()
```

Do not call `CleverTapPluginCustomTemplates.registerCustomTemplates`. It does not compile with a
plain string. The plugin already registers `DigiaTemplate`.

Add the CleverTap account ID and token: `CLEVERTAP_ACCOUNT_ID` and `CLEVERTAP_TOKEN`
`<meta-data>` in `AndroidManifest.xml`, and `CleverTapAccountID` and `CleverTapToken` in
`Info.plist`. Ask the user for them. If they skip, write placeholders. If the account has a
region (for example `in1`), also add `CLEVERTAP_REGION` and `CleverTapRegion`.

### MoEngage

Start MoEngage natively on both platforms, as MoEngage requires. Digia adds no native step.
Ask the user for the MoEngage App ID and data center. If they skip, write placeholders.

Android: create `MainApplication.kt` next to `MainActivity.kt`, in the same package, and set
`android:name=".MainApplication"` on `<application>`:

```kotlin
import com.moengage.core.DataCenter
import com.moengage.core.MoEngage
import com.moengage.flutter.MoEInitializer
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        MoEInitializer.initialiseDefaultInstance(applicationContext,
            MoEngage.Builder(this, "YOUR_MOENGAGE_APP_ID", DataCenter.DATA_CENTER_1))
    }
}
```

Note the spelling `initialise`. `DATA_CENTER_1` matches data center 1: use the user's.

Add Glide to `android/app/build.gradle(.kts)`. Without it, MoEngage stops the app when an in-app
campaign with an image arrives:

```kotlin
dependencies {
    implementation("com.github.bumptech.glide:glide:4.16.0")
}
```

iOS `AppDelegate`, with `import MoEngageSDK` and `import moengage_flutter_ios`:

```swift
MoEngageInitializer.sharedInstance.initializeDefaultInstance(
    MoEngageSDKConfig(appId: "YOUR_MOENGAGE_APP_ID", dataCenter: .data_center_01),
    launchOptions: launchOptions)
```

### WebEngage

Android, in a custom `Application` class (create it as in **MoEngage**):

```kotlin
WebengageInitializer.initialize(this,
    WebEngageConfig.Builder().setWebEngageKey("YOUR_WEBENGAGE_LICENSE").build())
```

The classes are `com.webengage.webengage_plugin.WebengageInitializer` and
`com.webengage.sdk.android.WebEngageConfig`.

iOS: add `WEGLicenseCode` to `Info.plist`. In `AppDelegate`, import `WebEngage` and
`digia_webengage_plugin`. Start WebEngage with a `DigiaDelegateProxy`, held in a property so it
stays alive. `DigiaSuppressPlugin.shared` is nil at launch, so use the proxy:

```swift
import digia_webengage_plugin

private let digiaNotifProxy = DigiaDelegateProxy()

WebEngage.sharedInstance().application(application,
    didFinishLaunchingWithOptions: launchOptions ?? [:],
    notificationDelegate: digiaNotifProxy)
```

Without it, WebEngage renders the Digia campaign itself.

## Debug deeplink

iOS: add `digia-engage` to `CFBundleURLSchemes` in `ios/Runner/Info.plist`. If the file has no
`CFBundleURLTypes`, add it:

```xml
<key>CFBundleURLTypes</key>
<array><dict><key>CFBundleURLSchemes</key><array><string>digia-engage</string></array></dict></array>
```

Android needs no step.

If `app_links`, `uni_links` or `go_router` handles incoming URLs, forward the Digia link first:

```dart
if (Digia.isDebugSettingsDeepLink(uri)) {
  Digia.openDebugSettings(context);
  return;
}
```

Use a `context` below the app's `Navigator`, for example the context of the current screen. If the
app has a `navigatorKey`, use `navigatorKey.currentContext!`.

## Build

- `flutter analyze`
- `flutter build apk --debug`
- `flutter build ios --simulator --debug --no-codesign`

## Check

| ID | Rule | Severity | CEP | Detect | Fix |
|---|---|---|---|---|---|
| FL-01 | Core package added | fail | all | `digia_engage:` in `pubspec.yaml` | Run **Dependencies**. |
| FL-02 | CEP plugin and CEP SDK added | fail | clevertap, moengage, webengage | both packages from **Dependencies** in `pubspec.yaml` | Add the pair. |
| FL-03 | `initialize` is awaited before `register` and `runApp` | fail | all | `await Digia.initialize(` in `main`, before `Digia.register(` (if any) and `runApp(` | Move the calls into that order. |
| FL-04 | Real API key | fail | all | `apiKey:` value is not `digia_xxx` | Put the key from the Digia dashboard. |
| FL-05 | One plugin registered | fail | clevertap, moengage, webengage | exactly one `Digia.register(` | Add the call from **Initialize and register**. |
| FL-15 | No stray plugin | fail | digia | no `Digia.register(` | Remove the call, or ask the user which CEP to use. |
| FL-16 | App events sent | warn | digia | at least one `Digia.trackEvent(` | Add **Digia-managed campaigns**. |
| FL-06 | One `DigiaHost` in the app builder | fail | all | exactly one `DigiaHost(`, inside `builder:` | Add **Host and screen tracking**. |
| FL-07 | Screen tracking | fail | all | `DigiaNavigatorObserver()` in `navigatorObservers` or GoRouter `observers`, or `Digia.setCurrentScreen(` | Add the observer. |
| FL-08 | Identity | warn | all | `Digia.setUserId(` and `Digia.clearUserId(` | Add **Identity**. |
| FL-09 | CleverTap native setup | fail | clevertap | `ActivityLifecycleCallback.register` in the Android `Application`, `CleverTap.autoIntegrate()` in `AppDelegate`, account ID on both platforms | Add the **CleverTap** steps. |
| FL-10 | MoEngage started, same instance passed | fail | moengage | `MoEngagePlugin(instance:` with the initialised `MoEngageFlutter` | Add the **MoEngage** steps. |
| FL-11 | WebEngage iOS delegate | fail | webengage | `DigiaDelegateProxy` held in a property and passed as `notificationDelegate` | Add the **WebEngage** steps. |
| FL-12 | iOS debug deeplink scheme | warn | all | `digia-engage` in `ios/Runner/Info.plist` `CFBundleURLSchemes` | Add **Debug deeplink**. |
| FL-13 | iOS deployment target | fail | all | `platform :ios, '15.0'` or later in `ios/Podfile` | Add the iOS step in **Dependencies**. |
| FL-14 | MoEngage Glide | fail | moengage | `com.github.bumptech.glide:glide` in `android/app/build.gradle(.kts)` | Add Glide from **MoEngage**. |
