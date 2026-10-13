# Android

Docs: `https://www.digia.tech/docs/developer/<cep>` (`clevertap`, `moengage`, `webengage`).
Digia-managed campaigns are not available on Android yet: ask the user which CEP to use.

## Dependencies

| CEP | Artifacts |
|---|---|
| clevertap | `tech.digia:engage` `tech.digia:engage-clevertap` |
| moengage | `tech.digia:engage` `tech.digia:engage-moengage` |
| webengage | `tech.digia:engage` `tech.digia:engage-webengage` |

Read the latest versions from Maven Central:
`https://repo1.maven.org/maven2/tech/digia/<artifact>/maven-metadata.xml` (`<release>`).
Add both artifacts to the app module, in the version catalog if the project has one. The
repositories need `mavenCentral()`.

Keep the app's own CEP SDK. The SDK needs `minSdk` 24 or later.

## Initialize and register

In `Application.onCreate`. Use the callback form: the two-argument `initialize` is a `suspend`
function. Do not wrap it in `runBlocking`.

```kotlin
class App : Application() {
    override fun onCreate() {
        DigiaCleverTapPlugin.prepareCleverTapCustomTemplates() // CleverTap only, first line
        ActivityLifecycleCallback.register(this)               // CleverTap only
        super.onCreate()
        Digia.initialize(applicationContext, DigiaConfig(apiKey = "YOUR_API_KEY")) { _ -> }
        Digia.register(DigiaCleverTapPlugin(applicationContext))
    }
}
```

| CEP | Register call |
|---|---|
| clevertap | `Digia.register(DigiaCleverTapPlugin(applicationContext))` (`com.digia.engage.clevertap`) |
| moengage | `Digia.register(MoEngagePlugin(applicationContext))` (`com.digia.moengage`) |
| webengage | `Digia.register(WebEngagePlugin())` (`com.digia.webengage`) |

Start the CEP SDK before `register`, as its own docs say. Register one plugin.

If the app has no `Application` class, create one and set `android:name` on `<application>` in
`AndroidManifest.xml`.

## CEP native steps

- CleverTap: call `DigiaCleverTapPlugin.prepareCleverTapCustomTemplates()` before CleverTap
  starts. Without it, CleverTap drops every Digia campaign. Add `CLEVERTAP_ACCOUNT_ID` and
  `CLEVERTAP_TOKEN` `<meta-data>` to `AndroidManifest.xml`. Ask the user for them. If they skip,
  write `YOUR_CLEVERTAP_ACCOUNT_ID` and `YOUR_CLEVERTAP_TOKEN`. If the account has a region
  (for example `in1`), also add `CLEVERTAP_REGION`.
- MoEngage: `MoEngage.initialiseDefaultInstance(MoEngage.Builder(this, "YOUR_MOENGAGE_APP_ID").build())`
  before `register`.
  Add `com.github.bumptech.glide:glide:4.16.0` to the app module. Without it, MoEngage stops the app
  when an in-app campaign with an image arrives.
- WebEngage: start WebEngage as its docs say, before `register`.

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

## Anchors and slots

An anchor marks the view that a tooltip or spotlight points at. A slot shows inline content
(banner, card, story).

Anchors: by default, wrap the icon of each bottom navigation item. Make the key from the item
label, in snake_case. Compose:

```kotlin
NavigationBarItem(
    icon = { DigiaAnchor("nav_home") { Icon(Icons.Default.Home, null) } },
    label = { Text("Home") }, selected = selected, onClick = onClick,
)
```

Views: wrap the target as the single child of `com.digia.engage.DigiaAnchorView` with
`app:anchorKey`. The items of a menu-based `BottomNavigationView` cannot be wrapped: tell the user,
and propose anchors on the main buttons instead.

Slots: find the screens with static content, for example a home, offers or profile screen. Propose
one place on each. Compose: `DigiaSlot("home_banner")`. Views:
`<com.digia.engage.DigiaSlotView app:placementKey="home_banner" android:layout_width="match_parent"
android:layout_height="wrap_content" />`. Add a slot only when the user agrees.

Give the user the list of keys. The marketer selects the same keys in the Digia dashboard.

## Identity

Next to the app's login and logout code: `Digia.setUserId(user.id)`, then on logout
`Digia.clearUserId()` and `Digia.clearAllInlineContent()`. Keep the CEP's own login call.

## Debug deeplink

No step. The SDK declares the `digia-engage://_digia/debug-settings` link in its own manifest.
It opens in debuggable builds only. Test with
`adb shell am start -a android.intent.action.VIEW -d "digia-engage://_digia/debug-settings" <package>`.

## Build

`./gradlew :app:assembleDebug`

## Check

| ID | Rule | Severity | CEP | Detect | Fix |
|---|---|---|---|---|---|
| AN-01 | Core and CEP plugin added | fail | all | `tech.digia:engage` and `tech.digia:engage-<cep>` in Gradle files or the version catalog | Add **Dependencies**. |
| AN-02 | Initialized in `Application.onCreate` | fail | all | `Digia.initialize(` in the class named by `android:name` | Add **Initialize and register**. |
| AN-03 | Real API key | fail | all | `apiKey =` value is not `YOUR_API_KEY` | Put the key from the Digia dashboard. |
| AN-04 | One plugin registered, after `initialize` and the CEP SDK start | fail | all | exactly one `Digia.register(`, after `Digia.initialize(` and the CEP start call | Add the call from **Initialize and register**. |
| AN-05 | Host present | fail | all | `DigiaHost {` or `DigiaHostView` | Add **Host**. |
| AN-06 | Screen tracking | fail | all | `DigiaScreen(` or `digiaScreen(` or `Digia.setCurrentScreen(` | Add **Screen tracking**. |
| AN-07 | Identity | warn | all | `Digia.setUserId(` and `Digia.clearUserId(` | Add **Identity**. |
| AN-08 | CleverTap native setup | fail | clevertap | `DigiaCleverTapPlugin.prepareCleverTapCustomTemplates()` first in `onCreate`, `ActivityLifecycleCallback.register(this)` before `super.onCreate()`, account ID in `AndroidManifest.xml` | Add the **CleverTap** step. |
| AN-10 | Callback form of `initialize` | fail | all | `Digia.initialize(` with a trailing callback, and no `runBlocking` around it | Use the call from **Initialize and register**. |
| AN-11 | MoEngage Glide | warn | moengage | `com.github.bumptech.glide:glide` in the app module or version catalog | Add Glide from the **MoEngage** step. |
