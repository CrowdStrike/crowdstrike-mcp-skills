#!/usr/bin/env bash
#
# crowdstrike-oauth2token.sh - CrowdStrike Falcon OAuth2 token headersHelper
#
# Used as the headersHelper for the crowdstrike MCP server entry in .mcp.json.
# Claude Code runs this script at session start and on reconnect, then merges
# the returned JSON headers into every request to the MCP server.
#
# Required environment variables (must be exported before launching Claude Code):
#   FALCON_CLIENT_ID     - CrowdStrike Falcon API client ID
#   FALCON_CLIENT_SECRET - CrowdStrike Falcon API client secret
#
# Optional environment variables:
#   FALCON_MEMBER_CID    - Member CID (for MSSP / Flight Control tenants)
#   FALCON_REGION        - Region detected at setup time (us-1, us-2, eu-1);
#                          baked into .mcp.json by mcp-server-setup.sh — do not
#                          set manually. Defaults to us-1 if absent.
#
# Output: JSON object of string key-value pairs to stdout, e.g.
#   {"Authorization": "Bearer eyJ..."}
#
# Requirements: curl

set -euo pipefail

if [[ -z "${FALCON_CLIENT_ID:-}" || -z "${FALCON_CLIENT_SECRET:-}" ]]; then
  echo '{"error": "FALCON_CLIENT_ID and FALCON_CLIENT_SECRET must be set"}' >&2
  exit 1
fi

case "${FALCON_REGION:-us-1}" in
  us-1) TOKEN_URL="https://api.crowdstrike.com/oauth2/token" ;;
  us-2) TOKEN_URL="https://api.us-2.crowdstrike.com/oauth2/token" ;;
  eu-1) TOKEN_URL="https://api.eu-1.crowdstrike.com/oauth2/token" ;;
  *)    TOKEN_URL="https://api.crowdstrike.com/oauth2/token" ;;
esac
if [[ -n "${FALCON_MEMBER_CID:-}" ]]; then
  TOKEN_URL="${TOKEN_URL}?member_cid=${FALCON_MEMBER_CID}"
fi

RESPONSE=$(curl -L --silent --fail --show-error \
  --request POST "${TOKEN_URL}" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${FALCON_CLIENT_ID}" \
  --data-urlencode "client_secret=${FALCON_CLIENT_SECRET}")

ACCESS_TOKEN=$(printf '%s' "${RESPONSE}" | grep -o '"access_token"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')

if [[ -z "${ACCESS_TOKEN}" ]]; then
  echo "crowdstrike-oauth2token.sh: failed to obtain access_token" >&2
  echo "${RESPONSE}" >&2
  exit 1
fi

printf '{"Authorization": "Bearer %s"}' "${ACCESS_TOKEN}"
