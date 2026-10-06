# Digia Engage agent skills

Agent skills that integrate the [Digia Engage](https://www.digia.tech/docs/developer) SDK into
your app.

| Skill | What it does |
|---|---|
| [`setup-digia-engage`](skills/setup-digia-engage/SKILL.md) | Adds Digia Engage to a React Native, Flutter, Android or iOS app with CleverTap, MoEngage, WebEngage or Digia-managed campaigns. If Digia Engage is already in the app, it checks the integration and reports each issue with its fix. |

## Install

Pick one route.

```bash
# Any agent that supports Agent Skills (Claude Code, Cursor, Codex, and others)
npx skills add Digia-Technology-Private-Limited/skills

# Claude Code plugin
/plugin marketplace add Digia-Technology-Private-Limited/skills
/plugin install digia-engage@digia-engage
```

## Use

Open your app's repository in your agent, commit or stash your changes, and run:

```
/setup-digia-engage
```

The skill detects your platform and CEP, asks for your Digia API key, makes the changes, builds
the app, and checks the result against the
[integration checklist](https://www.digia.tech/docs/developer/integration-checklist).

## License

[Business Source License 1.1](LICENSE).
