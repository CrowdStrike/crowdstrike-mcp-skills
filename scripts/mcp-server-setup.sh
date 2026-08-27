#!/usr/bin/env bash
#
# mcp-server-setup.sh - Generate .mcp.json for the CrowdStrike Falcon MCP server
#
# Exchanges credentials against the CrowdStrike OAuth2 endpoint to determine the
# correct regional MCP URL from the X-Cs-Region response header, then writes
# .mcp.json to the plugin root (or $OUTPUT_DIR if set).
#
# Required environment variables (must be exported before running):
#   FALCON_CLIENT_ID     - CrowdStrike Falcon API client ID
#   FALCON_CLIENT_SECRET - CrowdStrike Falcon API client secret
#
# Optional environment variables:
#   FALCON_MEMBER_CID    - Member CID (for MSSP / Flight Control tenants)
#   OUTPUT_DIR           - Directory to write .mcp.json into (default: plugin root)
#   PLUGIN_ROOT          - Absolute path to the installed plugin directory; set
#                          automatically by the setup skill via ${CLAUDE_PLUGIN_ROOT}
#
# Requirements: curl

set -euo pipefail

# ---------------------------------------------------------------------------
# 1. Validate required credentials
# ---------------------------------------------------------------------------
if [[ -z "${FALCON_CLIENT_ID:-}" || -z "${FALCON_CLIENT_SECRET:-}" ]]; then
  echo "ERROR: FALCON_CLIENT_ID and FALCON_CLIENT_SECRET must be set." >&2
  exit 1
fi

TOKEN_URL="https://api.crowdstrike.com/oauth2/token"
if [[ -n "${FALCON_MEMBER_CID:-}" ]]; then
  TOKEN_URL="${TOKEN_URL}?member_cid=${FALCON_MEMBER_CID}"
fi

# ---------------------------------------------------------------------------
# 2. Exchange credentials and extract the X-Cs-Region response header
# ---------------------------------------------------------------------------
echo "Contacting CrowdStrike API to determine your region..." >&2

HEADERS_FILE=$(mktemp)
trap 'rm -f "${HEADERS_FILE}"' EXIT

HTTP_STATUS=$(curl -L --silent --fail --show-error \
  --request POST "${TOKEN_URL}" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${FALCON_CLIENT_ID}" \
  --data-urlencode "client_secret=${FALCON_CLIENT_SECRET}" \
  --dump-header "${HEADERS_FILE}" \
  --output /dev/null \
  --write-out "%{http_code}" || true)

if [[ "${HTTP_STATUS}" != "201" && "${HTTP_STATUS}" != "200" ]]; then
  echo "ERROR: OAuth2 token request failed (HTTP ${HTTP_STATUS})." >&2
  echo "Please verify FALCON_CLIENT_ID and FALCON_CLIENT_SECRET are correct." >&2
  exit 1
fi

CS_REGION=$(grep --ignore-case "^x-cs-region:" "${HEADERS_FILE}" \
  | head -1 | awk '{print $2}' | tr -d '[:space:]')

if [[ -z "${CS_REGION}" ]]; then
  echo "ERROR: Could not determine region from X-Cs-Region response header." >&2
  exit 1
fi

echo "Detected region: ${CS_REGION}" >&2

# ---------------------------------------------------------------------------
# 3. Map region to MCP server URL
# ---------------------------------------------------------------------------
case "${CS_REGION}" in
  us-1) MCP_URL="https://mcp.crowdstrike.com/v1" ;;
  us-2) MCP_URL="https://mcp.us-2.crowdstrike.com/v1" ;;
  eu-1) MCP_URL="https://mcp.eu-1.crowdstrike.com/v1" ;;
  *)
    echo "ERROR: Unknown region '${CS_REGION}'. Cannot determine MCP server URL." >&2
    exit 1
    ;;
esac

echo "MCP server URL: ${MCP_URL}" >&2

# ---------------------------------------------------------------------------
# 4. Resolve path to crowdstrike-oauth2token.sh (bundled with this plugin)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${PLUGIN_ROOT:-$(dirname "${SCRIPT_DIR}")}"
PLUGIN_ROOT="${PLUGIN_ROOT%/}"
OAUTH_SCRIPT="${PLUGIN_ROOT}/scripts/crowdstrike-oauth2token.sh"

if [[ ! -f "${OAUTH_SCRIPT}" ]]; then
  echo "ERROR: Cannot locate crowdstrike-oauth2token.sh at '${OAUTH_SCRIPT}'." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 5. Write .mcp.json
# ---------------------------------------------------------------------------
OUTPUT_DIR="${OUTPUT_DIR:-${PLUGIN_ROOT}}"
OUTPUT_FILE="${OUTPUT_DIR}/.mcp.json"

HELPER_STRING="FALCON_CLIENT_ID=\${FALCON_CLIENT_ID} FALCON_CLIENT_SECRET=\${FALCON_CLIENT_SECRET} FALCON_REGION=${CS_REGION}"
if [[ -n "${FALCON_MEMBER_CID:-}" ]]; then
  HELPER_STRING="${HELPER_STRING} FALCON_MEMBER_CID=\${FALCON_MEMBER_CID}"
fi
HELPER_STRING="${HELPER_STRING} ${OAUTH_SCRIPT}"

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "${s}"
}

cat > "${OUTPUT_FILE}" <<EOF
{
  "mcpServers": {
    "crowdstrike": {
      "type": "http",
      "url": "$(json_escape "${MCP_URL}")",
      "headersHelper": "$(json_escape "${HELPER_STRING}")"
    }
  }
}
EOF

echo ""
echo "✓ Created ${OUTPUT_FILE}"
