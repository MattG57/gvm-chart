#!/bin/bash

# REQUIRED INPUTS
CLIENT_ID="Iv23liFU7U02m6ptmy4D"
CLIENT_SECRET="4592e8e20831e54653585f16b76c3992c7e9ffe5"
CODE="$1"

if [ -z "$CODE" ]; then
  echo "Usage: $0 <code-from-oauth-callback>"
  exit 1
fi

# STEP 1: Get Access Token
echo "🔑 Requesting access token from GitHub..."
TOKEN_RESPONSE=$(curl -s -X POST https://github.com/login/oauth/access_token \
  -H "Accept: application/json" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "code=${CODE}")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r .access_token)

if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to retrieve access token"
  echo "$TOKEN_RESPONSE"
  exit 1
fi

echo "✅ Access token acquired"

# STEP 2: Retrieve User Info
echo "🙋 Getting authenticated user info..."
USER=$(curl -s -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/user)
LOGIN=$(echo "$USER" | jq -r .login)
echo "👤 GitHub Login: $LOGIN"

# STEP 3: Check Org Membership
ORG="melisource"
echo "🏢 Checking org membership in '$ORG'..."
ORG_MEMBERSHIP=$(curl -s -H "Authorization: token ${ACCESS_TOKEN}" \
  https://api.github.com/user/memberships/orgs/${ORG})
echo "$ORG_MEMBERSHIP" | jq '{state, role, organization: .organization.login}'
# ➤ Expect: "state": "active", "role": "member"/"admin"

# STEP 4 (optional): Check Team Membership
TEAM="your-team-name"  # Replace this with actual team name
echo "👥 Checking team membership in '$TEAM'..."
TEAM_MEMBERSHIP=$(curl -s -H "Authorization: token ${ACCESS_TOKEN}" \
  https://api.github.com/orgs/${ORG}/teams/${TEAM}/memberships/${LOGIN})
echo "$TEAM_MEMBERSHIP" | jq '{state, role}'
# ➤ Expect: "state": "active", "role": "member"/"maintainer"

# STEP 5: Confirm Scopes
echo "🔍 Verifying granted OAuth scopes..."
curl -s -D - -o /dev/null -H "Authorization: token $ACCESS_TOKEN" https://api.github.com/user | \
  grep -i 'x-oauth-scopes'
# ➤ Look for required scopes: read:org, user:email, etc.
