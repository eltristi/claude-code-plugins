#!/bin/bash
# Detect if the app is already running
# Usage: bash detect-running.sh <project-type>
# Outputs JSON with running status

set -euo pipefail

PROJECT_TYPE="${1:?Usage: detect-running.sh <expo|laravel>}"

if [ "$PROJECT_TYPE" = "expo" ]; then
  METRO_RUNNING="false"
  APP_RUNNING="false"

  # Check Metro bundler
  if curl -s localhost:8081/status 2>/dev/null | grep -q "packager-status:running"; then
    METRO_RUNNING="true"
  fi

  # Check if app is on a simulator (iOS)
  if command -v xcrun &>/dev/null; then
    BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep -c "Booted" || echo "0")
    if [ "$BOOTED" -gt 0 ]; then
      APP_RUNNING="true"
    fi
  fi

  # Check if app is on emulator (Android)
  if command -v adb &>/dev/null; then
    DEVICES=$(adb devices 2>/dev/null | grep -c "emulator" || echo "0")
    if [ "$DEVICES" -gt 0 ]; then
      APP_RUNNING="true"
    fi
  fi

  cat <<EOF
{
  "running": $([ "$METRO_RUNNING" = "true" ] && [ "$APP_RUNNING" = "true" ] && echo "true" || echo "false"),
  "metro_running": ${METRO_RUNNING},
  "app_running": ${APP_RUNNING}
}
EOF

elif [ "$PROJECT_TYPE" = "laravel" ]; then
  DOCKER_RUNNING="false"
  APP_RESPONDING="false"
  APP_URL=""

  # Check Docker containers
  if docker compose ps --format json 2>/dev/null | jq -s '.' &>/dev/null; then
    RUNNING_COUNT=$(docker compose ps --format json 2>/dev/null | jq -s 'map(select(.State == "running")) | length')
    if [ "$RUNNING_COUNT" -gt 0 ]; then
      DOCKER_RUNNING="true"
    fi
  fi

  # Try to discover app URL from docker-compose
  COMPOSE_FILE="docker-compose.yml"
  [ ! -f "$COMPOSE_FILE" ] && COMPOSE_FILE="compose.yaml"

  if [ -f "$COMPOSE_FILE" ]; then
    # Try to find the web service port mapping
    PORT=$(docker compose port app 80 2>/dev/null | sed 's/.*://' || \
           docker compose port web 80 2>/dev/null | sed 's/.*://' || \
           docker compose port nginx 80 2>/dev/null | sed 's/.*://' || \
           echo "")
    if [ -n "$PORT" ]; then
      APP_URL="http://localhost:${PORT}"
    fi
  fi

  # Check if app responds
  if [ -n "$APP_URL" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" != "000" ] && [ "$HTTP_CODE" != "502" ] && [ "$HTTP_CODE" != "503" ]; then
      APP_RESPONDING="true"
    fi
  fi

  cat <<EOF
{
  "running": $([ "$DOCKER_RUNNING" = "true" ] && [ "$APP_RESPONDING" = "true" ] && echo "true" || echo "false"),
  "docker_running": ${DOCKER_RUNNING},
  "app_responding": ${APP_RESPONDING},
  "app_url": $(echo "${APP_URL:-}" | jq -R .)
}
EOF

else
  echo '{"error": "Unknown project type: '"$PROJECT_TYPE"'"}'
  exit 1
fi
