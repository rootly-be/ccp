# CCP — Claude Code Plugins by Rootly

A collection of plugins for [Claude Code](https://docs.anthropic.com/en/docs/build-with-claude/claude-code).

## Installation

```bash
# Add the marketplace (once)
/plugin marketplace add rootly-be/ccp

# Install a plugin
/plugin install <plugin-name>@ccp
```

## Available Plugins

| Plugin | Description | Commands |
|--------|-------------|----------|
| [**apex**](./plugins/apex/) | Structured development workflow: Analyze → Plan → Execute → Validate → Security → Review → Tests → Docs → CI/CD. Subagent-driven, autonomous pipeline. | `/apex:apex`, `/apex:apex-init` |

## Repository Structure

```
.claude-plugin/
└── marketplace.json        # Plugin catalogue
plugins/
├── apex/                   # APEX — Full dev workflow
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── README.md           # Detailed documentation
│   ├── commands/
│   ├── agents/
│   ├── skills/
│   └── hooks/
└── ...                     # Future plugins
```

## License

MIT
