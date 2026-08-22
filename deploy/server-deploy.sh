#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

sha="${1:-}"
if [[ ! "$sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Usage: $0 <40-character-git-sha>" >&2
  exit 2
fi

test -f production.env || {
  echo "Missing deploy/production.env" >&2
  exit 1
}

set -a
source production.env
set +a

: "${ACR_VPC_REGISTRY:?missing ACR_VPC_REGISTRY}"
: "${ACR_NAMESPACE:?missing ACR_NAMESPACE}"
: "${ACR_REPOSITORY:?missing ACR_REPOSITORY}"

image="${ACR_VPC_REGISTRY}/${ACR_NAMESPACE}/${ACR_REPOSITORY}:${sha}"
current_image=""
if [[ -f CURRENT_IMAGE ]]; then
  current_image="$(<CURRENT_IMAGE)"
fi

docker pull "$image"
architecture="$(docker image inspect "$image" --format '{{.Architecture}}')"
if [[ "$architecture" != "amd64" ]]; then
  echo "Refusing non-amd64 image: $architecture" >&2
  exit 1
fi

if [[ -n "$current_image" ]]; then
  printf '%s\n' "$current_image" >PREVIOUS_IMAGE
fi
printf 'AI_JOURNAL_IMAGE=%s\n' "$image" >.image.env.next
chmod 600 .image.env.next
mv .image.env.next .image.env

if ! docker compose --env-file .image.env up -d --wait; then
  if [[ -s PREVIOUS_IMAGE ]]; then
    previous_image="$(<PREVIOUS_IMAGE)"
    printf 'AI_JOURNAL_IMAGE=%s\n' "$previous_image" >.image.env
    docker compose --env-file .image.env up -d --wait
  fi
  exit 1
fi

for attempt in {1..12}; do
  # The host CA bundle may lag ISRG Root X2. Container health already checks
  # the app; this verifies local TLS routing, while GitHub verifies public trust.
  if curl --insecure --fail --silent --show-error \
    --resolve starzn.xyz:443:127.0.0.1 \
    --max-time 10 https://starzn.xyz/ >/dev/null; then
    printf '%s\n' "$image" >CURRENT_IMAGE
    echo "Deployed $image"
    exit 0
  fi
  sleep 5
done

echo "Public health check failed; restoring previous image." >&2
if [[ -s PREVIOUS_IMAGE ]]; then
  previous_image="$(<PREVIOUS_IMAGE)"
  printf 'AI_JOURNAL_IMAGE=%s\n' "$previous_image" >.image.env
  docker compose --env-file .image.env up -d --wait
fi
exit 1
