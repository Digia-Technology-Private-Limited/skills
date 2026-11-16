# Android

Docs: `https://www.digia.tech/docs/developer/<cep>` (`clevertap`, `moengage`, `webengage`).
Digia-managed campaigns (`digia`) have no docs page yet: follow this file.

## Dependencies

| CEP | Artifacts |
|---|---|
| digia | `tech.digia:engage` |
| clevertap | `tech.digia:engage` `tech.digia:engage-clevertap` |
| moengage | `tech.digia:engage` `tech.digia:engage-moengage` |
| webengage | `tech.digia:engage` `tech.digia:engage-webengage` |

Read the latest versions from Maven Central:
`https://repo1.maven.org/maven2/tech/digia/<artifact>/maven-metadata.xml` (`<release>`).
Add the artifacts to the app module, in the version catalog if the project has one. The
repositories need `mavenCentral()`.

With a CEP, keep the app's own CEP SDK. The SDK needs `minSdk` 24 or later.

## Initialize and register

In `Application.onCreate`. Use the callback form: the two-argument `initialize` is a `suspend`
function. Do not wrap it in `runBlocking`.

```kotlin
class App : Application() {
    override fun onCreate() {
        DigiaCleverTapPlugin.prepareCleverTapCustomTemplates() // CleverTap only, first line
        ActivityLifecycleCallback.register(this)               // CleverTap only
        super.onCreate()
        Digia.initialize(applicationContext, DigiaConfig(apiKey = "digia_xxx")) { _ -> }
        Digia.register(DigiaCleverTapPlugin(applicationContext)) // not for digia
    }
}
```

| CEP | Register call |
|---|---|
| clevertap | `Digia.register(DigiaCleverTapPlugin(applicationContext))` (`com.digia.engage.clevertap`) |
| moengage | `Digia.register(MoEngagePlugin(applicationContext))` (`com.digia.moengage`) |
| webengage | `Digia.register(WebEngagePlugin())` (`com.digia.webengage`) |

Start the CEP SDK before `register`, as its own docs say. Register one plugin. With `digia`,
register no plugin: `initialize` is the whole setup.

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
label, in snake_case. Compose: if the item shows a different icon when selected, wrap both
branches with the same key. Otherwise the selected tab has no anchor:

```kotlin
NavigationBarItem(
    icon = {
        DigiaAnchor("nav_home") {
            Icon(if (selected) Icons.Filled.Home else Icons.Outlined.Home, null)
        }
    },
    label = { Text("Home") }, selected = selected, onClick = onClick,
)
```

If the two icons sit in separate `if` branches, wrap each branch in `DigiaAnchor("nav_home")`.

Views: wrap the target as the single child of `com.digia.engage.DigiaAnchorView` with
`app:anchorKey`. The items of a menu-based `BottomNavigationView` cannot be wrapped: tell the user,
and propose anchors on the main buttons instead.

Slots: add them yourself, one per screen, on the home screen and on each screen with static
content, for example offers, profile, about, terms, FAQ or order success. Name the key after the
screen, in snake_case: `home_top`, `about_top`. Put the slot at the top of the screen's content,
below the app bar or header. A slot takes no space when no campaign is live. Compose:

```kotlin
Column(Modifier.verticalScroll(rememberScrollState())) {
    // Digia Engage: shows inline campaigns here. Takes no space when none is live.
    DigiaSlot("about_top", Modifier.fillMaxWidth())
    Text(aboutText)
}
```

Views: add it as the first child of the screen's content container:
`<com.digia.engage.DigiaSlotView app:placementKey="about_top" android:layout_width="match_parent"
android:layout_height="wrap_content" />`.

Ask the user before you add a slot inside a list, a grid or a form.

Give the user the list of keys. The marketer selects the same keys in the Digia dashboard.

## Identity

Next to the app's login and logout code: `Digia.setUserId(user.id)`, then on logout
`Digia.clearUserId()` and `Digia.clearAllInlineContent()`. Keep the CEP's own login call.

## Digia-managed campaigns

Only for `digia`. With a CEP, do not add `trackEvent` or `setUserAttributes`: the CEP receives
the app's events and user data.

A campaign triggers on app open, app foreground, a screen view (from **Screen tracking**), an
anchor or slot becoming visible, or an event that the app sends. Add the events and user
attributes yourself. Do not ask the user which ones.

### Events

Send Digia the events the app already tracks, with the same names and properties, so the
marketer sees the same event names in their analytics tool and in the Digia dashboard:

1. The app has an analytics wrapper that every event goes through, for example an
   `AnalyticsTracker.logEvent` around `FirebaseAnalytics.logEvent`: add one `Digia.trackEvent`
   line inside it.
2. No wrapper: add `Digia.trackEvent` next to each direct analytics call, such as
   `firebaseAnalytics.logEvent`, Mixpanel `track` or Amplitude `track`.
3. No analytics: add it at the app's key actions, such as sign up, login, search, add to cart,
   checkout and purchase. Use snake_case names, and pass the values already in scope.

```kotlin
fun logEvent(name: String, params: Map<String, Any?> = emptyMap()) {
    firebaseAnalytics.logEvent(name, bundleOf(*params.toList().toTypedArray()))
    // Digia Engage: lets Digia-managed campaigns trigger on this event.
    Digia.trackEvent(name, params)
}
```

`trackEvent` takes the event name (1 to 120 characters) and a `Map<String, Any?>` of
properties. Use `String`, number or `Boolean` values, or lists of them: rules compare these. Put
an amount in the properties, for example `mapOf("value" to 650, "currency" to "INR")`. The event
and property names appear in the dashboard after the first event arrives.

### User attributes

Campaign conditions compare these:

1. The app sets user properties in its analytics tool, for example
   `firebaseAnalytics.setUserProperty(name, value)`: send the same name and value with
   `Digia.setUserAttributes`, next to each call or inside the wrapper.
2. Otherwise, right after `Digia.setUserId`, send the profile fields the app already has on the
   user, such as name, email, phone, city, plan and sign-up date.

```kotlin
Digia.setUserId(user.id)
// Digia Engage: campaign conditions can compare these attributes.
Digia.setUserAttributes(
    mapOf(
        "name" to user.name,
        "email" to user.email,
        "city" to user.city,
        "signup_date" to user.createdAt.toString(), // ISO 8601
    ),
)
```

Values are `String`, number, `Boolean` or `List<String>`. Send dates as ISO 8601 strings. Leave
out fields that are null. Calls merge. `setUserAttributes` needs `setUserId` first.
`Digia.clearUserId()` clears them.

## Debug deeplink

No step. The SDK declares the `digia-engage://_digia/debug-settings` link in its own manifest.
It opens in debuggable builds only. Test with
`adb shell am start -a android.intent.action.VIEW -d "digia-engage://_digia/debug-settings" <package>`.

## Build

`./gradlew :app:assembleDebug`

## Check

| ID | Rule | Severity | CEP | Detect | Fix |
|---|---|---|---|---|---|
| AN-01 | Core and CEP plugin added | fail | all | `tech.digia:engage` in Gradle files or the version catalog, and `tech.digia:engage-<cep>` unless the CEP is `digia` | Add **Dependencies**. |
| AN-02 | Initialized in `Application.onCreate` | fail | all | `Digia.initialize(` in the class named by `android:name` | Add **Initialize and register**. |
| AN-03 | Real API key | fail | all | `apiKey =` value is not `digia_xxx` | Put the key from the Digia dashboard. |
| AN-04 | One plugin registered, after `initialize` and the CEP SDK start | fail | clevertap, moengage, webengage | exactly one `Digia.register(`, after `Digia.initialize(` and the CEP start call | Add the call from **Initialize and register**. |
| AN-05 | Host present | fail | all | `DigiaHost {` or `DigiaHostView` | Add **Host**. |
| AN-06 | Screen tracking | fail | all | `DigiaScreen(` or `digiaScreen(` or `Digia.setCurrentScreen(` | Add **Screen tracking**. |
| AN-07 | Identity | warn | all | `Digia.setUserId(` and `Digia.clearUserId(` | Add **Identity**. |
| AN-08 | CleverTap native setup | fail | clevertap | `DigiaCleverTapPlugin.prepareCleverTapCustomTemplates()` first in `onCreate`, `ActivityLifecycleCallback.register(this)` before `super.onCreate()`, account ID in `AndroidManifest.xml` | Add the **CleverTap** step. |
| AN-10 | Callback form of `initialize` | fail | all | `Digia.initialize(` with a trailing callback, and no `runBlocking` around it | Use the call from **Initialize and register**. |
| AN-11 | MoEngage Glide | warn | moengage | `com.github.bumptech.glide:glide` in the app module or version catalog | Add Glide from the **MoEngage** step. |
| AN-12 | No stray plugin | fail | digia | no `Digia.register(` | Remove the call, or ask the user which CEP to use. |
| AN-13 | App events sent | fail | digia | `Digia.trackEvent(` in the analytics wrapper or next to each analytics event call; with no analytics, at least one | Add **Events**. |
| AN-14 | User attributes sent | warn | digia | `Digia.setUserAttributes(` | Add **User attributes**. |
| AN-15 | Selected tab anchored | warn | all | each Compose navigation item with a `DigiaAnchor` and a different selected icon has the same anchor key on both icons | Wrap both icons as **Anchors and slots** says. |
