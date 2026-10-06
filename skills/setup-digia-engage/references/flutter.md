# Flutter

Docs: `https://www.digia.tech/docs/developer/<cep>` (`clevertap`, `moengage`, `webengage`).
Digia-managed campaigns are not available on Flutter yet: ask the user which CEP to use.

## Dependencies

| CEP | Packages |
|---|---|
| clevertap | `digia_engage` `digia_engage_clevertap` |
| moengage | `digia_engage` `digia_moengage_plugin` |
| webengage | `digia_engage` `digia_webengage_plugin` |

Run `flutter pub add <packages>`. The SDK needs Dart 3.6 and Flutter 3.29 or later.

Keep the app's own CEP SDK (`clevertap_plugin`, `moengage_flutter`, `webengage_flutter`). If
`pub get` reports a version conflict, constrain the app's CEP SDK to the range in the Digia
plugin's `pubspec.yaml`.

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
  await Digia.initialize(DigiaConfig(apiKey: 'YOUR_API_KEY'));
  Digia.register(DigiaCleverTapPlugin());
  runApp(const MyApp());
}
```

| CEP | Register call |
|---|---|
| clevertap | `Digia.register(DigiaCleverTapPlugin())` |
| moengage | `Digia.register(MoEngagePlugin(instance: moEngage))` |
| webengage | `Digia.register(DigiaWebEngagePlugin())` |

MoEngage: start MoEngage first, and pass the same instance.

```dart
final moEngage = MoEngageFlutter('YOUR_MOENGAGE_APP_ID');
moEngage.initialise();
await Digia.initialize(DigiaConfig(apiKey: 'YOUR_API_KEY'));
Digia.register(MoEngagePlugin(instance: moEngage));
```

Register one plugin. A second `register` replaces the first.

## Host and screen tracking

```dart
final navigatorKey = GlobalKey<NavigatorState>();

MaterialApp(
  navigatorKey: navigatorKey,
  navigatorObservers: [DigiaNavigatorObserver()],
  builder: (context, child) => DigiaHost(navigatorKey: navigatorKey, child: child!),
)
```

GoRouter: `GoRouter(navigatorKey: navigatorKey, observers: [DigiaNavigatorObserver()])` and
`MaterialApp.router(builder: ...)` with the same `DigiaHost`. Each `ShellRoute` needs its own
observer.

The observer reports `route.settings.name`. Give each route a `name`. For tabs in one route, call
`Digia.setCurrentScreen('tab_name')` on tab change. The names must match the screen names in the
Digia dashboard, case included.

Mount one `DigiaHost`. Two hosts show each nudge twice.

## Identity

Next to the app's existing login and logout code:

```dart
await Digia.setUserId(user.id);   // login
await Digia.clearUserId();        // logout
Digia.clearAllInlineContent();    // logout
```

Keep the CEP's own login call. It does not reach Digia.

## CEP native steps

### CleverTap

The Digia template registers itself on Android. Android still needs a custom `Application`
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
Import `CleverTapSDK` and `clevertap_plugin`:

```swift
CleverTapPluginCustomTemplates.registerCustomTemplates("DigiaTemplate")
CleverTap.autoIntegrate()
```

Add the CleverTap account ID and token: `CLEVERTAP_ACCOUNT_ID` and `CLEVERTAP_TOKEN`
`<meta-data>` in `AndroidManifest.xml`, and `CleverTapAccountID` and `CleverTapToken` in
`Info.plist`. Ask the user for them. If they skip, write placeholders.

### MoEngage

MoEngage starts natively on both platforms. No Digia native step.

Android, in a custom `Application` class declared in `AndroidManifest.xml`:

```kotlin
MoEInitializer.initialiseDefaultInstance(applicationContext,
    MoEngage.Builder(this, "YOUR_MOENGAGE_APP_ID", DataCenter.DATA_CENTER_1))
```

The class is `com.moengage.flutter.MoEInitializer`. Note the spelling `initialise`.

iOS `AppDelegate`, with `import MoEngageSDK` and `import moengage_flutter_ios`:

```swift
MoEngageInitializer.sharedInstance.initializeDefaultInstance(
    MoEngageSDKConfig(appId: "YOUR_MOENGAGE_APP_ID", dataCenter: .data_center_01),
    launchOptions: launchOptions)
```

### WebEngage

Android, in a custom `Application` class declared in `AndroidManifest.xml`:

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
  Digia.openDebugSettings(navigatorKey.currentContext!);
  return;
}
```

## Build

- `flutter analyze`
- `flutter build apk --debug`
- `flutter build ios --simulator --debug --no-codesign`

## Check

| ID | Rule | Severity | CEP | Detect | Fix |
|---|---|---|---|---|---|
| FL-01 | Core package added | fail | all | `digia_engage:` in `pubspec.yaml` | Run **Dependencies**. |
| FL-02 | CEP plugin and CEP SDK added | fail | all | both packages from **Dependencies** in `pubspec.yaml` | Add the pair. |
| FL-03 | `initialize` is awaited before `register` and `runApp` | fail | all | `await Digia.initialize(` in `main`, before `Digia.register(` and `runApp(` | Move the calls into that order. |
| FL-04 | Real API key | fail | all | `apiKey:` value is not `YOUR_API_KEY` | Put the key from the Digia dashboard. |
| FL-05 | One plugin registered | fail | all | exactly one `Digia.register(` | Add the call from **Initialize and register**. |
| FL-06 | One `DigiaHost` in the app builder | fail | all | exactly one `DigiaHost(`, inside `builder:` | Add **Host and screen tracking**. |
| FL-07 | Screen tracking | fail | all | `DigiaNavigatorObserver()` in `navigatorObservers` or GoRouter `observers`, or `Digia.setCurrentScreen(` | Add the observer. |
| FL-08 | Identity | warn | all | `Digia.setUserId(` and `Digia.clearUserId(` | Add **Identity**. |
| FL-09 | CleverTap native setup | fail | clevertap | `ActivityLifecycleCallback.register` in the Android `Application`, `registerCustomTemplates("DigiaTemplate")` before `CleverTap.autoIntegrate()` in `AppDelegate`, account ID on both platforms | Add the **CleverTap** steps. |
| FL-10 | MoEngage started, same instance passed | fail | moengage | `MoEngagePlugin(instance:` with the initialised `MoEngageFlutter` | Add the **MoEngage** steps. |
| FL-11 | WebEngage iOS delegate | fail | webengage | `DigiaDelegateProxy` held in a property and passed as `notificationDelegate` | Add the **WebEngage** steps. |
| FL-12 | iOS debug deeplink scheme | warn | all | `digia-engage` in `ios/Runner/Info.plist` `CFBundleURLSchemes` | Add **Debug deeplink**. |
