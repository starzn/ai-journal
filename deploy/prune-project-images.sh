#!/usr/bin/env bash

prune_project_images() {
  local current_release="${1:?missing current release}"
  local primary_repository="${2:?missing primary repository}"
  shift 2
  local repositories=("$@")
  local history_file="${PROJECT_RELEASE_HISTORY_FILE:-RELEASE_HISTORY}"
  local keep_releases=("$current_release")
  local created release repository tag candidate image_id
  local is_project_repository
  local history_source="$history_file"

  if [[ ! -f "$history_source" ]]; then
    history_source="${history_file}.bootstrap"
    : >"$history_source"
    while IFS=$'\t' read -r repository tag image_id; do
      if [[ "$repository" = "$primary_repository" && "$tag" =~ ^[0-9a-f]{40}$ ]]; then
        created="$(docker image inspect "$image_id" --format '{{.Created}}')"
        printf '%s\t%s\n' "$created" "$tag"
      fi
    done < <(docker image ls --no-trunc --format '{{.Repository}}\t{{.Tag}}\t{{.ID}}') |
      sort -r |
      cut -f2 >"$history_source"
  fi

  while IFS= read -r release; do
    [[ "$release" =~ ^[0-9a-f]{40}$ ]] || continue
    local already_kept=false
    for candidate in "${keep_releases[@]}"; do
      if [[ "$candidate" = "$release" ]]; then
        already_kept=true
        break
      fi
    done
    "$already_kept" && continue

    keep_releases+=("$release")
    (("${#keep_releases[@]}" >= 3)) && break
  done <"$history_source"

  rm -f "${history_file}.bootstrap"
  printf '%s\n' "${keep_releases[@]}" >"${history_file}.next"
  chmod 600 "${history_file}.next"
  mv "${history_file}.next" "$history_file"

  printf 'Keeping %s releases:' "${#keep_releases[@]}"
  printf ' %s' "${keep_releases[@]}"
  printf '\n'

  while IFS=$'\t' read -r repository tag; do
    is_project_repository=false
    for candidate in "${repositories[@]}"; do
      if [[ "$candidate" = "$repository" ]]; then
        is_project_repository=true
        break
      fi
    done
    "$is_project_repository" || continue

    release="${tag%-migrate}"
    [[ "$release" =~ ^[0-9a-f]{40}$ ]] || continue

    local should_keep=false
    for candidate in "${keep_releases[@]}"; do
      if [[ "$candidate" = "$release" ]]; then
        should_keep=true
        break
      fi
    done
    "$should_keep" && continue

    echo "Removing obsolete project image ${repository}:${tag}"
    docker image rm "${repository}:${tag}"
  done < <(docker image ls --format '{{.Repository}}\t{{.Tag}}')
}
