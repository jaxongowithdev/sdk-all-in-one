#!/usr/bin/env bash
# convertSDK.sh — auto-find google-services.json and map to all_in_one_sdk API response.
#
# Usage:
#   ./convertSDK.sh
#   ./convertSDK.sh --ios
#   ./convertSDK.sh --facebook
#   ./convertSDK.sh --package com.rakhoitv.nova.app
#
# Looks for exact filenames (no path argument):
#   google-services.json, GoogleService-Info.plist, facebook.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IOS_PLIST=""
FACEBOOK_JSON=""
PACKAGE_FILTER=""
ANALYTICS_ENABLED="true"
AUTO_IOS=false
AUTO_FACEBOOK=false

usage() {
  sed -n '2,11p' "$0" | sed 's/^# \?//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --ios) AUTO_IOS=true; shift ;;
    --ios=*) IOS_PLIST="${1#*=}"; shift ;;
    --facebook) AUTO_FACEBOOK=true; shift ;;
    --facebook=*) FACEBOOK_JSON="${1#*=}"; shift ;;
    --package) PACKAGE_FILTER="${2:?--package requires package name}"; shift 2 ;;
    --no-analytics) ANALYTICS_ENABLED="false"; shift ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required. Install: brew install jq" >&2
  exit 1
fi

# Find first existing file named exactly $1 under candidate directories.
find_named_file() {
  local name="$1"
  local dir
  local candidates=(
    "$SCRIPT_DIR"
    "$PWD"
    "$SCRIPT_DIR/android/app"
    "$SCRIPT_DIR/example/android/app"
    "$SCRIPT_DIR/ios/Runner"
    "$SCRIPT_DIR/example/ios/Runner"
  )

  local d="$PWD"
  local i=0
  while [[ $i -lt 6 ]]; do
    candidates+=("$d")
    d="$(dirname "$d")"
    [[ "$d" == "/" ]] && break
    i=$((i + 1))
  done

  for dir in "${candidates[@]}"; do
    [[ -f "${dir}/${name}" ]] || continue
    echo "${dir}/${name}"
    return 0
  done
  return 1
}

GOOGLE_SERVICES="$(find_named_file "google-services.json" || true)"
if [[ -z "$GOOGLE_SERVICES" ]]; then
  echo "Error: google-services.json not found." >&2
  echo "Place it next to convertSDK.sh, in project root, or under android/app/." >&2
  exit 1
fi

if [[ "$AUTO_IOS" == true && -z "$IOS_PLIST" ]]; then
  IOS_PLIST="$(find_named_file "GoogleService-Info.plist" || true)"
fi

if [[ "$AUTO_FACEBOOK" == true && -z "$FACEBOOK_JSON" ]]; then
  FACEBOOK_JSON="$(find_named_file "facebook.json" || true)"
fi

# Pick Android client: match --package or first entry with android_client_info
if [[ -n "$PACKAGE_FILTER" ]]; then
  CLIENT_INDEX="$(jq -r --arg pkg "$PACKAGE_FILTER" '
    [.client | to_entries[] | select(.value.client_info.android_client_info.package_name == $pkg) | .key][0] // empty
  ' "$GOOGLE_SERVICES")"
  if [[ -z "$CLIENT_INDEX" ]]; then
    echo "Error: no client with package_name=$PACKAGE_FILTER in $GOOGLE_SERVICES" >&2
    exit 1
  fi
else
  CLIENT_INDEX="$(jq -r '
    ([.client | to_entries[] | select(.value.client_info.android_client_info != null) | .key][0]) // 0
  ' "$GOOGLE_SERVICES")"
fi

ANDROID_APP_ID="$(jq -r --argjson i "$CLIENT_INDEX" '.client[$i].client_info.mobilesdk_app_id // empty' "$GOOGLE_SERVICES")"
API_KEY="$(jq -r --argjson i "$CLIENT_INDEX" '.client[$i].api_key[0].current_key // empty' "$GOOGLE_SERVICES")"
PACKAGE_NAME="$(jq -r --argjson i "$CLIENT_INDEX" '.client[$i].client_info.android_client_info.package_name // empty' "$GOOGLE_SERVICES")"
PROJECT_NUMBER="$(jq -r '.project_info.project_number // empty' "$GOOGLE_SERVICES")"
PROJECT_ID="$(jq -r '.project_info.project_id // empty' "$GOOGLE_SERVICES")"
STORAGE_BUCKET="$(jq -r '.project_info.storage_bucket // empty' "$GOOGLE_SERVICES")"

if [[ -z "$ANDROID_APP_ID" || -z "$API_KEY" || -z "$PROJECT_NUMBER" || -z "$PROJECT_ID" ]]; then
  echo "Error: could not read required Firebase fields from $GOOGLE_SERVICES" >&2
  exit 1
fi

# iOS: env > auto-found plist > fallback Android app id
IOS_GOOGLE_APP_ID="${IOS_GOOGLE_APP_ID:-}"
IOS_BUNDLE_ID="${IOS_BUNDLE_ID:-}"

if [[ -z "$IOS_GOOGLE_APP_ID" && -n "$IOS_PLIST" && -f "$IOS_PLIST" ]]; then
  if command -v plutil >/dev/null 2>&1; then
    IOS_GOOGLE_APP_ID="$(plutil -extract GOOGLE_APP_ID raw -o - "$IOS_PLIST" 2>/dev/null || true)"
    IOS_BUNDLE_ID="$(plutil -extract BUNDLE_ID raw -o - "$IOS_PLIST" 2>/dev/null || true)"
  else
    IOS_GOOGLE_APP_ID="$(grep -A1 '<key>GOOGLE_APP_ID</key>' "$IOS_PLIST" | tail -1 | sed -E 's/.*<string>([^<]+)<\/string>.*/\1/')"
    IOS_BUNDLE_ID="$(grep -A1 '<key>BUNDLE_ID</key>' "$IOS_PLIST" | tail -1 | sed -E 's/.*<string>([^<]+)<\/string>.*/\1/')"
  fi
fi

if [[ -z "$IOS_GOOGLE_APP_ID" ]]; then
  IOS_GOOGLE_APP_ID="$ANDROID_APP_ID"
fi

FIREBASE_JSON="$(jq -n \
  --arg googleAppId "$ANDROID_APP_ID" \
  --arg gcmSenderId "$PROJECT_NUMBER" \
  --arg apiKey "$API_KEY" \
  --arg projectId "$PROJECT_ID" \
  --arg storageBucket "$STORAGE_BUCKET" \
  '{
    googleAppId: $googleAppId,
    gcmSenderId: $gcmSenderId,
    apiKey: $apiKey,
    projectId: $projectId,
    storageBucket: (if $storageBucket == "" then null else $storageBucket end)
  } | with_entries(select(.value != null))')"

FACEBOOK_BLOCK="null"
if [[ -n "$FACEBOOK_JSON" && -f "$FACEBOOK_JSON" ]]; then
  FACEBOOK_BLOCK="$(jq '
    {
      applicationId: (.applicationId // .appId // .facebookAppId),
      clientToken: (.clientToken // null),
      displayName: (.displayName // null),
      autoLogAppEventsEnabled: (.autoLogAppEventsEnabled // null),
      advertiserIdCollectionEnabled: (.advertiserIdCollectionEnabled // null)
    } | with_entries(select(.value != null))
  ' "$FACEBOOK_JSON")"
elif [[ -n "${FACEBOOK_APPLICATION_ID:-}" ]]; then
  FACEBOOK_BLOCK="$(jq -n \
    --arg applicationId "$FACEBOOK_APPLICATION_ID" \
    --arg clientToken "${FACEBOOK_CLIENT_TOKEN:-}" \
    --arg displayName "${FACEBOOK_DISPLAY_NAME:-}" \
    '{
      applicationId: $applicationId,
      clientToken: (if $clientToken == "" then null else $clientToken end),
      displayName: (if $displayName == "" then null else $displayName end)
    } | with_entries(select(.value != null))')"
fi

jq -n \
  --argjson firebase "$FIREBASE_JSON" \
  --argjson facebook "$FACEBOOK_BLOCK" \
  '{
    firebase: $firebase,
    facebook: (if $facebook == null then null else $facebook end)
  } | with_entries(select(.value != null))'
