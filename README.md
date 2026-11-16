<p align="center">
  <a href="https://www.digia.tech">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
      <img src="assets/logo-light.svg" alt="Digia" width="240">
    </picture>
  </a>
</p>

<h3 align="center">Ship in-app experiences, not releases.</h3>

<p align="center">
  Agent skills that add <a href="https://www.digia.tech">Digia Engage</a> to your mobile app in one prompt.
</p>

<p align="center">
  <a href="https://www.digia.tech/docs/developer">Docs</a> ·
  <a href="https://www.digia.tech">Website</a> ·
  <a href="https://dispatch.digia.tech">Blog</a>
</p>

---

Digia Engage lets your growth team ship nudges, bottom sheets, coachmarks, quizzes, scratch
cards and NPS surveys to your app with no code and no app release. It runs on the CEP you
already use (CleverTap, MoEngage or WebEngage), or with its own campaigns on React Native and
Flutter.

The `setup-digia-engage` skill does the integration for you. Your coding agent adds the SDK,
connects your CEP or Digia's own campaigns, and checks the result. It does not build the app.

## Install

Any agent (Claude Code, Codex, Cursor, OpenCode, GitHub Copilot, Gemini CLI, Windsurf and others):

```sh
npx skills add Digia-Technology-Private-Limited/skills -s setup-digia-engage -g -y
```

Run it in a terminal, or ask your coding agent to run it. It installs the skill once for your
user, for each coding agent it finds on your machine, and adds no files to your app's
repository. Then start a new agent chat in your app's repository, so the agent loads the skill.

Or use the plugin system of your agent:

| Agent | Command |
|---|---|
| Claude Code | `/plugin marketplace add Digia-Technology-Private-Limited/skills`<br>`/plugin install digia-engage@digia-engage` |
| Codex | `codex plugin marketplace add Digia-Technology-Private-Limited/skills`, then install Digia Engage from `/plugins` |
| Cursor | Settings → Plugins → add from GitHub repository `Digia-Technology-Private-Limited/skills` |
| GitHub Copilot CLI | `copilot plugin marketplace add Digia-Technology-Private-Limited/skills`<br>`copilot plugin install digia-engage@digia-engage` |
| Gemini CLI | `gemini skills install https://github.com/Digia-Technology-Private-Limited/skills.git --path skills/setup-digia-engage` |

## Use

1. Open your app's repository in your agent.
2. Commit or stash your changes, so you can review the diff.
3. Ask: **"Set up Digia Engage"**, or run `/setup-digia-engage`.

| Your app | What the skill does |
|---|---|
| Has no Digia Engage | Detects your platform and CEP (CleverTap, MoEngage or WebEngage). Asks whether to use that CEP or Digia's own campaigns; with no CEP, uses Digia's own campaigns on React Native and Flutter. Asks for your Digia API key (you can add it later). Adds the SDK, checks the result, lists each dependency override and each problem it causes, then offers to help build the app. |
| Has Digia Engage | Checks the integration and reports each issue with its file, line and fix. It offers to fix them. |

## Supported setups

| Platform | CleverTap | MoEngage | WebEngage | Digia-managed |
|---|:-:|:-:|:-:|:-:|
| React Native | ✅ | ✅ | ✅ | ✅ |
| Flutter | ✅ | ✅ | ✅ | ✅ |
| Android | ✅ | ✅ (beta) | ✅ | — |
| iOS | ✅ (beta) | ✅ (beta) | ✅ | — |

## After setup

- Run a live test from the [Digia Engage Dashboard](https://www.digia.tech).
- Open SDK Debug Settings on a device with `digia-engage://_digia/debug-settings`.
- Need help? Write to [info@digia.tech](mailto:info@digia.tech).

## License

[Business Source License 1.1](LICENSE).
