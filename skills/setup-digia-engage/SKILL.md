---
name: setup-digia-engage
description: Integrate the Digia Engage SDK into a React Native, Flutter, Android or iOS app with CleverTap, MoEngage, WebEngage or Digia-managed campaigns, or check an existing integration. Use when the user asks to add, set up, install, upgrade, audit or debug Digia Engage.
---

# Set up Digia Engage

The **Check** table in the stack reference defines what a correct integration is.

## 1. Guard the working tree

Run `git status --porcelain` in the app root.

- Output is not empty: stop. Ask the user to commit or stash, then wait.
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

Detect the **CEP** from dependencies: CleverTap, MoEngage or WebEngage SDK packages.

- One CEP SDK found: use it.
- Two found: ask the user which one Digia Engage uses.
- None found on React Native: ask whether to use Digia-managed campaigns (`digia`) or to add a CEP.
- None found on other stacks: ask which CEP to use.

Read the stack reference now. Done when stack and CEP are both known.

## 3. Load the rules

From the **Check** table in the stack reference, keep the rules whose CEP column is `all` or
names this CEP.

Done when you hold the list of applicable rule IDs.

## 4. Pick the path

Search the source for the Digia core package and a `Digia.initialize` call.

- Neither found: take the **Integrate** path (step 5).
- Either found: take the **Check** path (step 6).

## 5. Integrate

Follow the stack reference, section by section, for this CEP:

1. Add the dependencies at their latest versions, with the command in the stack reference.
   The stack reference is the authority for code.
2. Ask the user for the Digia API key. If they skip, write `YOUR_API_KEY` and continue. Check
   then reports the key rule as a fail. Leave that fail for the user.
3. Add initialize, plugin registration, host, screen tracking and the CEP native steps.
4. Match the app's existing code style, entry points and navigation library.
5. Build the app with the command in the stack reference. Fix errors until the build passes.

Show a short diff summary: each file changed, and why. Then run step 6 on the result.

Done when the build passes and the diff summary is shown.

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

If any rule fails, offer to fix them. On yes, apply the fixes, build, and check again.

End with the next steps: run a live test from the Digia Engage Dashboard, and open SDK Debug
Settings on the device (`digia-engage://_digia/debug-settings`).

Done when every applicable rule has a result and the report is shown.
