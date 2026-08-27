---
name: crowdstrike-mcp:setup
description: Set up the CrowdStrike Falcon MCP server. Checks for required credentials, runs mcp-server-setup.sh to detect the correct regional URL and write .mcp.json, then confirms successful installation.
allowed-tools: Bash
model: sonnet
user-invocable: true
disable-model-invocation: false
---

<objective>
Configure the CrowdStrike Falcon MCP server for this project by:

1. Verifying the required environment variables are set
2. Running `mcp-server-setup.sh` to exchange credentials, detect the user's
   Falcon region, and write a `.mcp.json` file in the plugin's directory
3. Confirming successful installation

The skill should be conversational but efficient — a single user message
(`/crowdstrike-mcp:setup`) should complete the entire flow without unnecessary
back-and-forth unless credentials are missing.
</objective>

<context>
Plugin root: ${CLAUDE_PLUGIN_ROOT}

Environment check:
- FALCON_CLIENT_ID set:     !`[[ -n "${FALCON_CLIENT_ID:-}" ]] && echo "YES" || echo "NO"`
- FALCON_CLIENT_SECRET set: !`[[ -n "${FALCON_CLIENT_SECRET:-}" ]] && echo "YES" || echo "NO"`
- FALCON_MEMBER_CID set:    !`[[ -n "${FALCON_MEMBER_CID:-}" ]] && echo "YES (${FALCON_MEMBER_CID})" || echo "NO (optional)"`

Existing .mcp.json: !`[[ -f "${CLAUDE_PLUGIN_ROOT}/.mcp.json" ]] && echo "EXISTS" || echo "NOT FOUND"`

Scripts:
- ${CLAUDE_PLUGIN_ROOT}/scripts/mcp-server-setup.sh
- ${CLAUDE_PLUGIN_ROOT}/scripts/crowdstrike-oauth2token.sh
</context>

<process>

## Step 1: Check credentials

Read the context block above.

**If FALCON_CLIENT_ID or FALCON_CLIENT_SECRET is "NO":**

Stop and tell the user exactly what to do:

```
To use the CrowdStrike MCP server, you must first export your Falcon API credentials:

  export FALCON_CLIENT_ID="<your client ID>"
  export FALCON_CLIENT_SECRET="<your client secret>"

Optional — required only for MSSP / Flight Control tenants:
  export FALCON_MEMBER_CID="<member CID>"

You can obtain API credentials in the Falcon console under
API Clients & Keys > Create API Client.

Once exported, re-run /crowdstrike-mcp:setup.
```

Do not proceed further.

**If both variables are set:** continue to Step 2.

## Step 2: Run mcp-server-setup.sh

Execute the setup script:

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" "${CLAUDE_PLUGIN_ROOT}/scripts/mcp-server-setup.sh"
```

Show the script's stdout/stderr output to the user verbatim.

**If the script exits non-zero:** report the error and suggest the user check
their credentials or network connectivity, then stop.

## Step 3: Confirm installation

If the script succeeded, tell the user:

```
Setup complete! The Falcon MCP server has been configured.
```

</process>

<success_criteria>
- .mcp.json written to the plugin root directory containing a valid mcpServers.crowdstrike entry
- headersHelper points to the bundled crowdstrike-oauth2token.sh
- User has been told the installation was successful
- Credential values are NEVER echoed in conversation output
</success_criteria>
