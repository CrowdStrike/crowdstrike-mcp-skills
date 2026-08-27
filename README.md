![CrowdStrike Falcon](/images/cs-logo.png?raw=true)

# CrowdStrike MCP Skills

[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/CrowdStrike/crowdstrike-mcp-skills/releases/tag/v1.0.0)

The CrowdStrike MCP Skills connect supported AI applications to CrowdStrike MCP. The included setup skill authenticates with CrowdStrike MCP and configures the MCP connection using your exported API client credentials.

For more info about CrowdStrike MCP, see the [CrowdStrike MCP documentation](https://docs.crowdstrike.com/access?ft:originId=tefc5682).

## Prerequisites

- Supported AI application:
    - Claude Code v2.1.69 or later
- Falcon API client with the scopes and permissions required for the tools you want to use. For more info, see [Managing your API clients](https://docs.crowdstrike.com/r/en-US/kgsgkjd3/va186f1a).

## Connect to CrowdStrike MCP

Complete the following steps. Unless otherwise noted, run the commands in your AI application.

1\. In your terminal, export your API client ID and secret as environment variables.

```shell
export FALCON_CLIENT_ID=<your-client-id>
export FALCON_CLIENT_SECRET=<your-client-secret>
```

Optional: If you’re connecting as a Falcon Flight Control parent CID and want CrowdStrike MCP to access a specific child CID, also export the child CID ID.

```shell
export FALCON_MEMBER_CID=<child-cid-id>
```

2\. Add the CrowdStrike MCP plugin marketplace.

```
/plugin marketplace add CrowdStrike/crowdstrike-mcp-skills
```

3\. Install the plugin.

```
/plugin install crowdstrike-mcp@crowdstrike-mcp-skills-marketplace
```

4\. Reload plugins so your AI application recognizes the newly installed plugin.

```
/reload-plugins
```

Note: If the plugin is still not available after reloading, restart your AI application.

5\. Run the setup skill.

```
/crowdstrike-mcp:setup
```

The setup skill uses your exported API client credentials to authenticate with CrowdStrike MCP and automatically configure the appropriate CrowdStrike MCP server connection.

6\. Reload plugins.

```
/reload-plugins --force
```

Force a plugin reload to apply the updated MCP server configuration.

7\. Verify the connection.  
The plugin is now installed and connected. To verify, ask your AI application a question about your Falcon environment, such as:

* “Show my critical detections from the past 24 hours.”
* “Search for the 10 most recent user login events.”
* “List hosts currently under network containment.”

## Authentication

The CrowdStrike MCP plugin automatically manages authentication with CrowdStrike MCP using your API client credentials. During setup, the plugin obtains an OAuth 2.0 access token and configures the MCP server connection. All requests to CrowdStrike MCP include a valid bearer token in the Authorization header.

Access tokens expire after 30 minutes. In Claude Code 2.119.3 and later, the plugin automatically obtains a new token before the current token expires. Earlier supported versions do not support automatic token renewal. After the token expires, run this command to reconnect to CrowdStrike MCP to obtain a new token:
```
/mcp reconnect plugin:crowdstrike-mcp:crowdstrike
```

## License

For licensing information, see [LICENSE](LICENSE).
