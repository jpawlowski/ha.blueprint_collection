#!/bin/bash
# Blueprint collection library
# shellcheck disable=SC2034  # Variables are used by sourcing scripts
#
# Provides shared constants and helpers for scripts that operate on the
# Home Assistant blueprints in this repository.
#
# Exported variables (available after sourcing):
#   BLUEPRINTS_ROOT     — "blueprints"
#   BLUEPRINT_DOMAINS   — (automation script template)
#
# Provided functions:
#   list_blueprint_files — print all blueprint YAML files, NUL-separated

BLUEPRINTS_ROOT="blueprints"
BLUEPRINT_DOMAINS=(automation script template)

# list_blueprint_files: print all *.yaml files under blueprints/<domain>/,
# NUL-separated so callers can safely read paths containing spaces:
#   while IFS= read -r -d '' file; do ...; done < <(list_blueprint_files)
list_blueprint_files() {
    local domain
    for domain in "${BLUEPRINT_DOMAINS[@]}"; do
        [[ -d "$BLUEPRINTS_ROOT/$domain" ]] || continue
        find "$BLUEPRINTS_ROOT/$domain" -type f -name '*.yaml' -print0
    done
}
