![CrowdStrike Falcon](/images/cs-logo.png?raw=true)

# Falcon MCP Skills

[![Version](https://img.shields.io/badge/version-1.5.0-blue)](https://github.com/CrowdStrike/falcon-mcp-skills/releases/tag/v1.0.0)

AI coding assistant skills for the [CrowdStrike MCP Server](#) apps.  

## Getting Started

### Prerequisites

- **CrowdStrike Account** with API Client credentials
- **Claude Code** — required to run the `/plugin` and `/crowdstrike-mcp:setup` slash commands
- **AI Coding Assistant**: Claude Code

### Installation & Setup
**1. Export your Falcon credentials**
```bash
export FALCON_CLIENT_ID=<your-client-id>
export FALCON_CLIENT_SECRET=<your-client-secret>
export FALCON_MEMBER_CID=<your-member-cid>  # optional
```

**2. Add the marketplace**
```/plugin marketplace add git@github.com:CrowdStrike/falcon-mcp-skills.git```

**3. Install the plugin**
```
`/plugin install falcon-mcp-skills`
```

**4. Reload plugins**
```
/reload-plugins
```

**5. Run the setup skill**
```
/crowdstrike-mcp:setup
```

**6. Reload plugins**

```
/reload-plugins --force
```

## Skills

| Skill                     | Purpose                                                                                                  |
|---------------------------|----------------------------------------------------------------------------------------------------------|
| `crowdstrike-mcp:setup`   | Sets up the CrowdStrike MCP server with client credentials                                               |

## License

See [LICENSE](LICENSE) for details.
