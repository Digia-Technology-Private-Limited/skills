---
name: setup-digia-engage
description: Integrate the Digia Engage SDK into a React Native, Flutter, Android or iOS app with CleverTap, MoEngage, WebEngage or Digia-managed campaigns, or check an existing integration. Use when the user asks to add, set up, install, upgrade, audit or debug Digia Engage.
---

# Set up Digia Engage

The **Check** table in the stack reference defines what a correct integration is.

## 1. Guard the working tree

Run `git status --porcelain` in the app root. Ignore untracked agent skill folders, such as
`.agents/`, `.claude/skills/`, `.cursor/skills/` and `.windsurf/skills/`. Installing this skill
can create them. Tell the user they can commit them or add them to `.gitignore`.

- Other output: stop. Ask the user to commit or stash, then wait.
- No Git repository: tell the user that you cannot show a clean diff, and ask to continue.

Done when the tree is clean, or the user has said to continue.

## 2. Detect the stack and the CEP

Detect the **stack** from the app root:

| Signal | Stack | Reference |
|---|---|---|
| `package.json` with `react-native` | React Native | [rn.md](references/rn.md) |
| `pubspec.yaml` with `flutter` | Flutter | [flutter.md](references/flutter.md) |
| `build.gradle(.kts)` with `com.android.application`, no RN or Flutter | Android | [android.md](references/android.md) |
| `.xcodeproj` or `Package.swift`, no RN or Flutter | iOS | [ios.md](references/ios.md) |

Detect the **CEP** from dependencies: CleverTap, MoEngage or WebEngage SDK packages. Digia works
with all three on every stack. Any other CEP counts as none found.

Ask the user, in one prompt. Use your question tool if you have one (for example
`AskUserQuestion`), else ask in chat and wait:

- Which setup to use. Always ask, even when the app has a CEP or already calls
  `Digia.initialize`. Offer:
  - **Digia-managed campaigns**, which is `digia`. Digia decides when each campaign shows. No CEP
    plugin.
  - **Digia with <the CEP you found>**. The CEP decides when each campaign shows, and Digia shows
    it.
  - **Digia with <the CEP you found> and Digia-managed campaigns**, which is `dmc`. As above, and
    Digia also runs the campaigns that the campaign team marks **Digia decides**.

  Offer the two CEP options for each CEP found. No CEP found: offer **Digia-managed campaigns**,
  and **Digia with CleverTap**, **MoEngage** or **WebEngage**. The
  app already calls `Digia.initialize`: mark the setup it uses now as current.
- The Digia API key, if they have one. They can skip it and add it later.
- Whether gamification is turned on for their Digia project: **Yes** or **No**. Default **No**:
  Digia turns it on per client, and most apps do not have it. The app already calls
  `Digia.openRewards`: mark **Yes** as current. Flutter: do not ask. Flutter has no gamification;
  if the user asks for it, say so.

Read the stack reference and [shared.md](references/shared.md) now. Done when the stack, the CEP
and the gamification answer are known.

## 3. Load the rules

From the **Check** table in the stack reference, keep the rules whose CEP column is `all` or
names this CEP. For `dmc`, also keep the rules marked `dmc`. If gamification is on, also keep the
rules marked `gamification`.

Done when you hold the list of applicable rule IDs.

## 4. Pick the path

Search the source for the Digia core package and a `Digia.initialize` call.

- Neither found: take the **Integrate** path (step 5).
- Either found: take the **Check** path (step 6).

## 5. Integrate

Follow the stack reference, section by section, for this CEP:

1. Add the dependencies as the stack reference says, at the versions it gives or from the source
   it names. The stack reference is the authority for code.
2. Write the API key from step 2. If the user skipped it, write `digia_xxx` and continue. Check
   then reports the key rule as a fail. Leave that fail for the user.
3. Add initialize, plugin registration, host, screen tracking and the CEP native steps.
4. Add anchors to the bottom navigation, and slots, as **Anchors and slots** in the stack
   reference says.
5. For `digia` and `dmc`, add events and user attributes as **Digia-managed campaigns** in the
   stack reference says.
6. If gamification is on, add **Gamification** from the stack reference.
7. Match the app's existing code style, entry points and navigation library.
8. Add a short comment, one or two lines, at each change in the app's code. Say why the change is
   there, for example `// Digia Engage: shows in-app campaigns on top of the app.` Skip files that
   do not allow comments, such as JSON.
9. Do not change the version of a package that the app already has. If Digia needs a different
   version: Flutter, add a `dependency_overrides` entry as `flutter.md` says, and list each
   override in the summary; other stacks, tell the user and change nothing without consent.
10. Run the static check: `flutter analyze` for Flutter, `npx tsc --noEmit` for React Native when
   the app has `tsconfig.json`. Native Android and iOS have no fast check without a build: read
   the diff again instead. If an error comes from your change or an override, do not change
   unrelated app code to fix it. Tell the user each problem and its cause, for example a
   `flutter_svg` version mismatch that breaks `precachePicture`.

Do not build the app. A build can need signing, native tools or secrets that only the user has.

Show a short summary with these parts. Leave out a part that has nothing in it:

- **Files changed**: each file, and why.
- **Anchors and slots**: each key and where it is.
- **Events and attributes**: each `trackEvent` and `setUserAttributes` call you added, its file,
  and the analytics call it mirrors.
- **Gamification**: where the rewards entry is, the app scheme for the rewards link, and where
  the app gets `userHash` from its server, or that the server side is still to do.
- **Dependency overrides**: one line each, `<package>: app has <version>, Digia needs
  <version>, overridden to <version>`, and why Digia needs it, for example "digia_engage 2.3.0
  needs connectivity_plus 6 or 7". Say that the override can break code that uses the old version.
- **Static check**: each error or warning that your change or an override causes, with its file,
  the cause and a fix, for example "`lib/splash.dart:12` — `precachePicture` was removed in
  flutter_svg 2, which the override brings in. Fix: use the flutter_svg 2 API." An error in a
  file you did not change, with no overridden package, was likely there before: say so.
- **API key**: if you wrote `digia_xxx`, say where to put the real key.

Then run step 6 on the result.

Done when the diff summary is shown.

## 6. Check

Apply every applicable rule. For each rule, search the source with its **Detect** column. Record
`pass` with `file:line` evidence, or the rule's severity (`fail` or `warn`) when it is not met.

Report in chat:

```
Digia Engage check — <stack> × <CEP>

❌ RN-05 fail  App.tsx — no <DigiaHost />. Fix: add <DigiaHost /> as the last child of the root view.
⚠️ RN-08 warn  no setUserId call. Fix: call Digia.setUserId on login.
✅ RN-01 pass  package.json:14

<n> pass · <n> warn · <n> fail
```

List fails first, then warns, then passes. Give the **Fix** for each fail and warn.

If any rule fails, offer to fix them. On yes, apply the fixes and check again.

If the source has no anchor or slot, recommend **Anchors and slots** from the stack reference.

Ask the user if they want help to build the app. On yes, use the command in **Build** in the stack
reference. Fix the errors that your changes cause. Tell the user about the other errors.

End with the next steps: run a live test from the Digia Engage Dashboard, and open SDK Debug
Settings on the device. The screen opens in debug builds only:

- Android: `adb shell am start -a android.intent.action.VIEW -d "digia-engage://_digia/debug-settings" <package>`
- iOS Simulator: `xcrun simctl openurl booted "digia-engage://_digia/debug-settings"`
- iOS device: open `digia-engage://_digia/debug-settings` from Safari or Notes.

Also give the steps that apply to this setup:

- **Dashboard setting**: in the Digia Engage Dashboard, under **Settings → General → CEP
  integration**, choose **Digia** for `digia`. For `dmc`, keep the CEP and turn on **Allow
  Digia-managed experiences**. The campaign team then picks **Digia decides** on each campaign
  that Digia should run.
- **CleverTap DigiaTemplate**: once per CleverTap project, before the first In-App campaign. Log
  in a user on a debug build with CleverTap's `onUserLogin`, mark that user as a test profile in
  CleverTap, and open the app. `prepareCleverTapCustomTemplates()` registers `DigiaTemplate`
  (on Flutter, the plugin does). Confirm it under **In-App → Templates** in CleverTap.
- **App version condition**: with a CEP, add an app version condition to each campaign: the
  first app release with Digia Engage, or later. Older app versions cannot show the campaign.
- **Own popups**: if the app shows its own popups or a payment flow, use
  `Digia.setCampaignsSuppressed`, as **More options** in the stack reference says.
- **User hash**: if the team connects data or turns on **Settings → User verification**, pass
  `userHash`, as **Identity** in the stack reference says. With gamification, see the next item.
- **Gamification**: hand the backend team the **Server side** list in
  [shared.md](references/shared.md#gamification): the `userHash`, the webhooks with their
  signature check, and the reward used callback. Keep **Project settings → User verification**
  on: with it off, any user ID can claim rewards. Reward links use the app's own scheme. With a
  CEP, the campaign team connects each CEP campaign to its Digia campaign with
  `digia_campaign_key`. Test plays do not show on the rewards page.
- **Names to share**: give the campaign team the screen names, events and their properties, user
  attributes, anchor keys and slot keys.

A CEP campaign shows only when the app sends its trigger event to the CEP. A Digia-managed
campaign shows when its trigger happens in the app: app open, a screen view, or an event the app
sends to Digia. The API key must be
from the Digia project that has the campaign. For the log lines that explain a missing campaign,
see [shared.md](references/shared.md#debug-log-lines).

Done when every applicable rule has a result and the report is shown.
