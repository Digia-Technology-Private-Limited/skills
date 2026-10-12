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
already use: CleverTap, MoEngage or WebEngage.

The `setup-digia-engage` skill does the integration for you. Your coding agent adds the SDK,
connects your CEP, builds the app, and checks the result.

## Install

Any agent (Claude Code, Codex, Cursor, OpenCode, GitHub Copilot, Gemini CLI, Windsurf and others):

```sh
npx skills add Digia-Technology-Private-Limited/skills -s setup-digia-engage
```

The command asks which agents to install for. Add `-g` to install for your user, not for the
project.

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
| Has no Digia Engage | Detects your platform and CEP, asks for your Digia API key, adds the SDK, builds the app, then checks the result. |
| Has Digia Engage | Checks the integration and reports each issue with its file, line and fix. It offers to fix them. |

## Supported setups

| Platform | CleverTap | MoEngage | WebEngage | Digia-managed |
|---|:-:|:-:|:-:|:-:|
| React Native | ✅ | ✅ | ✅ | ✅ |
| Flutter | ✅ ¹ | ✅ | ✅ | — |
| Android | ✅ | ✅ (beta) | ✅ | — |
| iOS | ✅ (beta) | ✅ (beta) | ✅ | — |

¹ Needs `digia_engage_clevertap` 2.0.0.

## After setup

- Run a live test from the [Digia Engage Dashboard](https://www.digia.tech).
- Open SDK Debug Settings on a device with `digia-engage://_digia/debug-settings`.
- Need help? Write to [info@digia.tech](mailto:info@digia.tech).

## License

[Business Source License 1.1](LICENSE).
