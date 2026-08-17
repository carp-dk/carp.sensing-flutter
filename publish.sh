#!/usr/bin/env bash
# Publish packages whose local version is not on pub.dev yet, dependencies first.
# Usage: ./publish.sh [--publish] [dir ...]   # no dirs = all, in dependency order
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Dependencies first: a package can only be published once what it depends on is live.
PACKAGES=(
  carp_serializable
  carp_core
  carp_mobile_sensing
  packages/carp_apps_package
  packages/carp_audio_package
  packages/carp_communication_package
  packages/carp_connectivity_package
  packages/carp_context_package
  packages/carp_esense_package
  packages/carp_health_package
  packages/carp_movesense_package
  packages/carp_movisens_package
  packages/carp_polar_package
  packages/carp_survey_package
  backends/carp_webservices
  backends/carp_backend
)

version_of() { sed -n 's/^version: *//p' "$1/pubspec.yaml" | head -1; }
name_of() { sed -n 's/^name: *//p' "$1/pubspec.yaml" | head -1; }

# Per-version endpoint: no piping into grep, which would break under `pipefail`
# once grep -q closes the pipe early on a large response.
is_published() { # name version
  curl -sf -o /dev/null "https://pub.dev/api/packages/$1/versions/$2"
}

pending=()
for dir in "${PACKAGES[@]}"; do
  name=$(name_of "$dir")
  version=$(version_of "$dir")
  if is_published "$name" "$version"; then
    printf '  %-28s %-8s already published\n' "$name" "$version"
  else
    printf '* %-28s %-8s to publish\n' "$name" "$version"
    pending+=("$dir")
  fi
done

[ ${#pending[@]} -eq 0 ] && { echo "Nothing to publish."; exit 0; }

publish=false
[ "${1:-}" = "--publish" ] && { publish=true; shift; }

# Optional dir filter, so a subset can go out while keeping the dependency order.
if [ $# -gt 0 ]; then
  filtered=()
  for dir in "${pending[@]}"; do
    for want in "$@"; do [ "$dir" = "${want%/}" ] && filtered+=("$dir"); done
  done
  pending=("${filtered[@]}")
  printf 'Selected %d of the above.\n' "${#pending[@]}"
fi

if ! $publish; then
  echo
  echo "Re-run with --publish to publish the ${#pending[@]} package(s) above."
  exit 0
fi

[ -n "$(git status --porcelain)" ] && { echo "Worktree is dirty."; exit 1; }

# ponytail: no upfront validation of all packages - a dependent cannot resolve until
# its dependency is live. On failure, re-run: published packages are skipped.
for dir in "${pending[@]}"; do
  name=$(name_of "$dir")
  version=$(version_of "$dir")
  echo "== publishing $name $version"
  # Drop pub's cached version lists, else a just-published dependency looks missing.
  rm -rf "${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev/.cache"
  (cd "$dir" && dart pub publish --force)

  # Wait for pub.dev to serve it, so the next package can resolve it.
  for _ in $(seq 60); do
    is_published "$name" "$version" && break
    sleep 5
  done
done
