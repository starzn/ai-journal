#!/usr/bin/env bash
set -euo pipefail

readonly ai_journal_deploy_command="${SSH_ORIGINAL_COMMAND:-}"

if [[ ! "$ai_journal_deploy_command" =~ ^deploy-ai-journal\ ([0-9a-f]{40})$ ]]; then
  echo "This key may only deploy an immutable AI Journal release." >&2
  exit 126
fi

exec /srv/apps/ai-journal/server-deploy.sh "${BASH_REMATCH[1]}"
