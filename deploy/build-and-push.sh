#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Refusing to publish a dirty working tree. Commit or intentionally remove local changes first." >&2
  exit 1
fi

public_registry="${ACR_PUBLIC_REGISTRY:-crpi-3wwavql7koh25y7y.cn-beijing.personal.cr.aliyuncs.com}"
namespace="${ACR_NAMESPACE:-starzn_deploy}"
repository="${ACR_REPOSITORY:-ai-journal-web}"
sha="$(git rev-parse HEAD)"
image="${public_registry}/${namespace}/${repository}:${sha}"
deploy_tag="deploy-ai-journal-${sha}"

docker buildx build \
  --platform linux/amd64 \
  --tag "$image" \
  --push \
  .

docker buildx imagetools inspect "$image" | grep -q 'linux/amd64'
git tag "$deploy_tag" "$sha"
git push origin "$deploy_tag"

echo "Published $image and pushed $deploy_tag"
