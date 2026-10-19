#!/usr/bin/env bash
#
# check-local.sh — validate every lab against a LOCAL checkout of
# AstroLumina-Terraform-Library, so labs can be tested before the Library
# change is merged to main.
#
# For each labs/*/ directory:
#   1. copy it to .local-check/<lab>/
#   2. rewrite the git:: module source prefix to the local Library path
#   3. terraform init -backend=false -input=false
#   4. terraform validate
#
# Prints PASS/FAIL per lab. Exits non-zero if any lab fails.
#
# Overridable via environment:
#   LIB_PATH           path to a local AstroLumina-Terraform-Library checkout
#                      (default: sibling of this repo, i.e. ../AstroLumina-Terraform-Library)
#   TF_PLUGIN_CACHE_DIR  shared Terraform plugin cache to speed up init
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_PATH="${LIB_PATH:-$(cd "$REPO_ROOT/.." && pwd)/AstroLumina-Terraform-Library}"
LABS_DIR="$REPO_ROOT/labs"
WORK_DIR="$REPO_ROOT/.local-check"

# The check workspace is regenerated on every run: .local-check/ is
# disposable and gitignored, so stale copies never mask fresh results.
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# Shared plugin cache (keeps repeated init runs fast)
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-/tmp/opencode/tf-plugin-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"

MODULE_SOURCE_PREFIX='git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/'

if [[ ! -d "$LIB_PATH/modules" ]]; then
  echo "ERROR: Library checkout not found at: $LIB_PATH" >&2
  echo "       Set LIB_PATH=/path/to/AstroLumina-Terraform-Library and retry." >&2
  exit 1
fi

failed_labs=()
checked=0

for lab in "$LABS_DIR"/*/; do
  [[ -d "$lab" ]] || continue
  lab_name="$(basename "$lab")"
  lab_work="$WORK_DIR/$lab_name"

  cp -r "$lab" "$lab_work"
  find "$lab_work" -type f -name '*.tf' -exec sed -i "s|${MODULE_SOURCE_PREFIX}|${LIB_PATH}/modules/|g" {} +
  # Local paths take no query parameters: drop the ?ref=... pin the git::
  # sources carry, or Terraform rejects the rewritten path.
  find "$lab_work" -type f -name '*.tf' -exec sed -i -E 's|\?ref=[A-Za-z0-9._/-]+||g' {} +

  checked=$((checked + 1))

  if terraform -chdir="$lab_work" init -backend=false -input=false >/dev/null 2>&1 \
     && terraform -chdir="$lab_work" validate >/dev/null 2>&1; then
    echo "PASS  $lab_name"
  else
    echo "FAIL  $lab_name (see $lab_work — init/validate output suppressed; rerun manually for details)"
    failed_labs+=("$lab_name")
  fi
done

if (( checked == 0 )); then
  echo "No labs found in $LABS_DIR — nothing to validate." >&2
  exit 1
fi

echo
if (( ${#failed_labs[@]} == 0 )); then
  echo "All $checked labs passed."
  exit 0
fi

echo "${#failed_labs[@]} of $checked labs FAILED: ${failed_labs[*]}" >&2
exit 1
