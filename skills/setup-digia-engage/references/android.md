# Android

Docs: `https://www.digia.tech/docs/developer/<cep>` (`clevertap`, `moengage`, `webengage`).
Get the latest versions from Maven Central (`tech.digia`). Digia-managed campaigns are not available on
Android yet: ask the user which CEP to use.

## Dependencies

| CEP | Artifacts |
|---|---|
| clevertap | `tech.digia:engage` `tech.digia:engage-clevertap` |
| moengage | `tech.digia:engage` `tech.digia:engage-moengage` |
| webengage | `tech.digia:engage` `tech.digia:engage-webengage` |

Add them to the app module, in the version catalog if the project has one. The repositories
need `mavenCentral()`. Keep the app's own CEP SDK.

## Initialize and register

In `Application.onCreate`. Use the callback form: the two-argument `initialize` is a `suspend`
function. Keep the call off `runBlocking`.

```kotlin
class App : Application() {
    override fun onCreate() {
        DigiaCleverTapPlugin.prepareCleverTapCustomTemplates() // CleverTap only, first line
        ActivityLifecycleCallback.register(this)               // CleverTap only
        super.onCreate()
        Digia.initialize(this, DigiaConfig(apiKey = "YOUR_API_KEY")) { _ -> }
        Digia.register(DigiaCleverTapPlugin(this))
    }
}
```

| CEP | Register call |
|---|---|
| clevertap | `Digia.register(DigiaCleverTapPlugin(this))` (`com.digia.engage.clevertap`) |
| moengage | `Digia.register(MoEngagePlugin(this))` (`com.digia.moengage`) |
| webengage | `Digia.register(WebEngagePlugin())` (`com.digia.webengage`) |

Start the CEP SDK before `register`, as its own docs say. Register one plugin. A second
`register` replaces the first.

## Host

Compose: wrap the root content once.

```kotlin
setContent { AppTheme { DigiaHost { AppNavHost() } } }
```

Views: add `com.digia.engage.DigiaHostView` to the root layout of each activity, on top of the
content, with `match_parent` size.

## Screen tracking

Compose: call `DigiaScreen("home")` in each screen composable. Views: call `digiaScreen("home")`
in `onResume` of each activity or fragment. The names must match the screen names in the Digia
dashboard, case included.

## Identity

Next to the app's login and logout code: `Digia.setUserId(user.id)`, then on logout
`Digia.clearUserId()` and `Digia.clearAllInlineContent()`. Keep the CEP's own login call.

## Debug deeplink

No step. The SDK declares `digia-engage://_digia/debug-settings` in its manifest. It works in
debuggable builds only. Test with
`adb shell am start -a android.intent.action.VIEW -d "digia-engage://_digia/debug-settings" <package>`.

## Build

`./gradlew :app:assembleDebug`

## v1 upgrade

| v1 | v2 |
|---|---|
| `DigiaCEPDelegate`, `healthCheck`, `teardown` | Use the published plugin class. |
| `forwardScreen`, `notifyEvent` | `DigiaScreen` or `digiaScreen` |
| `runBlocking { Digia.initialize(...) }` | Callback form of `initialize` |
