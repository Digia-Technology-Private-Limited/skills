# Flutter

Docs: `https://www.digia.tech/docs/developer/<cep>.md` (`clevertap`, `moengage`, `webengage`).
Read the install section for the latest package versions. Digia-managed campaigns are not
available on Flutter yet: ask the user which CEP to use.

## Dependencies

| CEP | Packages |
|---|---|
| clevertap | `digia_engage` `digia_engage_clevertap` |
| moengage | `digia_engage` `digia_moengage_plugin` |
| webengage | `digia_engage` `digia_webengage_plugin` |

Run `flutter pub add <packages>`. Keep the app's own CEP SDK (`clevertap_plugin`,
`moengage_flutter`, `webengage_flutter`). The SDK needs Dart 3.6 and Flutter 3.29 or later.

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

Android: a custom `Application` class, declared in `AndroidManifest.xml` `android:name`:

```kotlin
class MainApplication : FlutterApplication() {
    override fun onCreate() {
        ActivityLifecycleCallback.register(this)
        super.onCreate()
    }
}
```

iOS `AppDelegate`, after `GeneratedPluginRegistrant.register(with: self)`:

```swift
CleverTapPluginCustomTemplates.registerCustomTemplates("DigiaTemplate")
CleverTap.autoIntegrate()
```

Add the CleverTap account ID and token to `AndroidManifest.xml` and `Info.plist` as the CleverTap
docs say.

### MoEngage

Use the normal MoEngage Flutter setup, including the native initializer in `AppDelegate` and the
`Application` class. No Digia native step.

### WebEngage

iOS `AppDelegate`: start WebEngage with a Digia delegate proxy. Hold it in a property so it stays
alive:

```swift
import digia_webengage_plugin

private let digiaNotifProxy = DigiaDelegateProxy()

WebEngage.sharedInstance().application(application,
    didFinishLaunchingWithOptions: launchOptions,
    notificationDelegate: digiaNotifProxy)
```

Without it, WebEngage renders the Digia campaign itself.

## Debug deeplink

iOS: add `digia-engage` to `CFBundleURLSchemes` in `ios/Runner/Info.plist`. Android needs no step.

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
- `flutter build ios --simulator --debug`

## v1 upgrade

| v1 | v2 |
|---|---|
| `DigiaCEPDelegate`, `healthCheck`, `teardown` in a custom plugin | Use the published plugin class. |
| `Digia.forwardScreen(...)`, `notifyEvent` | `DigiaNavigatorObserver` or `Digia.setCurrentScreen(...)` |
| `registerPlaceholder` | `DigiaSlot('key')` |
