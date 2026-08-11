#!/usr/bin/env bash
#
# initialize.sh - One-time setup script for the Home Assistant Blueprint Collection template
#
# Replaces the template placeholders throughout the repository with your own
# collection identity, then deletes itself.
#
# WARNING: This script can only be run ONCE. After execution, it will be removed.
#
# Usage:
#   ./initialize.sh                                          # Interactive mode
#   ./initialize.sh --dry-run                                # Simulate without changes
#   ./initialize.sh --title TITLE --author-folder NAME --repo USER/REPO [--force]
#

set -euo pipefail

# ── Template placeholders (what gets replaced) ───────────────────────────────
readonly TPL_AUTHOR_FOLDER="ha_blueprint_author"
readonly TPL_TITLE="Blueprint Collection"
readonly TPL_REPO="jpawlowski/ha.blueprint_collection"

# ── Colors ───────────────────────────────────────────────────────────────────
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

print_color() { printf "%b%s%b\n" "$1" "$2" "$NC"; }
print_header() {
    echo ""
    print_color "$BOLD$BLUE" "══ $1 ══"
    echo ""
}
print_info() { print_color "$CYAN" "ℹ $1"; }
print_success() { print_color "$GREEN" "✓ $1"; }
print_warning() { print_color "$YELLOW" "⚠ $1"; }
print_error() { print_color "$RED" "✗ $1" >&2; }
print_step() { printf "    → %b\n" "$1"; }

# ── Arguments ────────────────────────────────────────────────────────────────
DRY_RUN=false
UNATTENDED=false
FORCE=false
PARAM_TITLE=""
PARAM_AUTHOR_FOLDER=""
PARAM_REPO=""
PARAM_MAINTAINER=""

usage() {
    cat <<EOF
Home Assistant Blueprint Collection - Initialization Script

Usage:
  ./initialize.sh                                       Interactive mode
  ./initialize.sh --dry-run                             Simulate without changes
  ./initialize.sh [OPTIONS] --force                     Unattended mode

Options:
  --title TITLE             Collection display title (e.g. "Jane's Blueprints")
  --author-folder NAME      Author folder under blueprints/<domain>/ (snake_case,
                            e.g. "jane_doe"). Becomes part of every import path.
  --repo USER/REPO          GitHub repository (e.g. "janedoe/ha-blueprints")
  --maintainer NAME         Maintainer handle for badges (defaults to repo owner)
  --dry-run, --simulate     Show what would change without changing anything
  --force                   Skip confirmation prompts
  --help, -h                Show this help

Examples:
  ./initialize.sh
  ./initialize.sh --dry-run
  ./initialize.sh --title "Jane's Blueprints" --author-folder jane_doe \\
                  --repo janedoe/ha-blueprints --force
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
    --dry-run | --simulate)
        DRY_RUN=true
        shift
        ;;
    --title)
        PARAM_TITLE="$2"
        UNATTENDED=true
        shift 2
        ;;
    --author-folder | --author)
        PARAM_AUTHOR_FOLDER="$2"
        UNATTENDED=true
        shift 2
        ;;
    --repo | --repository)
        PARAM_REPO="$2"
        UNATTENDED=true
        shift 2
        ;;
    --maintainer)
        PARAM_MAINTAINER="$2"
        shift 2
        ;;
    --force)
        FORCE=true
        shift
        ;;
    --help | -h)
        usage
        exit 0
        ;;
    *)
        print_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

# ── Safety guards ────────────────────────────────────────────────────────────

# Is this the upstream template repository itself?
is_original_template_repo() {
    git rev-parse --git-dir >/dev/null 2>&1 || return 1
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    [[ "$remote_url" =~ jpawlowski.*(ha\.)?blueprint[_.-]?collection ]]
}

# Has this repository already been initialized?
is_already_initialized() {
    # The template author folder is gone → renamed already
    [[ -d "blueprints/automation/${TPL_AUTHOR_FOLDER}" ]] || return 0
    return 1
}

if is_original_template_repo && [[ "$FORCE" != true ]]; then
    print_header "⚠️  Original Template Repository Detected"
    print_warning "This appears to be the upstream ${TPL_REPO} repository!"
    echo ""
    print_info "This script is meant for repositories created FROM this template."
    echo ""
    print_color "$CYAN" "  👤 Creating your own collection:"
    print_color "$GREEN" "     Use the 'Use this template' button on GitHub, then run this"
    print_color "$GREEN" "     script in your new repository."
    echo ""
    print_color "$CYAN" "  🔧 Template maintainer testing changes:"
    print_color "$YELLOW" "     ./initialize.sh --force --dry-run"
    echo ""
    print_error "Initialization cancelled for safety."
    exit 1
fi

if is_already_initialized && [[ "$FORCE" != true ]]; then
    print_header "Already Initialized"
    print_warning "blueprints/automation/${TPL_AUTHOR_FOLDER}/ does not exist."
    print_info "This repository appears to have been initialized already."
    print_info "Use --force to run anyway."
    exit 1
fi

# ── Validation ───────────────────────────────────────────────────────────────

validate_author_folder() {
    [[ "$1" =~ ^[a-z][a-z0-9_]*$ ]]
}

validate_repo() {
    [[ "$1" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]
}

# ── Gather input ─────────────────────────────────────────────────────────────

COLLECTION_TITLE=""
AUTHOR_FOLDER=""
REPO_SLUG=""
MAINTAINER=""

detect_repo_slug() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    [[ -n "$remote_url" ]] || return 1
    remote_url="${remote_url#git@github.com:}"
    remote_url="${remote_url#https://github.com/}"
    remote_url="${remote_url%.git}"
    validate_repo "$remote_url" && echo "$remote_url"
}

if [[ "$UNATTENDED" == true ]]; then
    COLLECTION_TITLE="$PARAM_TITLE"
    AUTHOR_FOLDER="$PARAM_AUTHOR_FOLDER"
    REPO_SLUG="$PARAM_REPO"

    [[ -n "$COLLECTION_TITLE" ]] || {
        print_error "--title is required in unattended mode"
        exit 1
    }
    [[ -n "$AUTHOR_FOLDER" ]] || {
        print_error "--author-folder is required in unattended mode"
        exit 1
    }
    [[ -n "$REPO_SLUG" ]] || {
        REPO_SLUG=$(detect_repo_slug) || {
            print_error "--repo is required (could not detect from git remote)"
            exit 1
        }
    }
else
    print_header "Home Assistant Blueprint Collection - Initialization"
    print_info "This configures the template for your own collection."
    print_info "It runs once and then deletes itself."
    echo ""

    # Title
    while [[ -z "$COLLECTION_TITLE" ]]; do
        read -r -p "$(printf "%bCollection title%b (e.g. \"Jane's Blueprints\"): " "$BOLD" "$NC")" COLLECTION_TITLE
        [[ -n "$COLLECTION_TITLE" ]] || print_error "Title cannot be empty"
    done

    # Author folder
    default_author=$(echo "$COLLECTION_TITLE" |
        tr '[:upper:]' '[:lower:]' |
        sed -E "s/'//g; s/[^a-z0-9]+/_/g; s/^_+//; s/_+$//")
    echo ""
    print_info "The author folder becomes part of the import path on every user's"
    print_info "instance (config/blueprints/automation/<author>/). Use something"
    print_info "identifiably yours — your GitHub handle works well."
    while [[ -z "$AUTHOR_FOLDER" ]]; do
        read -r -p "$(printf "%bAuthor folder%b [%s]: " "$BOLD" "$NC" "$default_author")" AUTHOR_FOLDER
        AUTHOR_FOLDER="${AUTHOR_FOLDER:-$default_author}"
        if ! validate_author_folder "$AUTHOR_FOLDER"; then
            print_error "Must be snake_case: lowercase letters, digits, underscores; starting with a letter"
            AUTHOR_FOLDER=""
        fi
    done

    # Repository
    default_repo=$(detect_repo_slug || echo "")
    echo ""
    while [[ -z "$REPO_SLUG" ]]; do
        if [[ -n "$default_repo" ]]; then
            read -r -p "$(printf "%bGitHub repository%b [%s]: " "$BOLD" "$NC" "$default_repo")" REPO_SLUG
            REPO_SLUG="${REPO_SLUG:-$default_repo}"
        else
            read -r -p "$(printf "%bGitHub repository%b (USER/REPO): " "$BOLD" "$NC")" REPO_SLUG
        fi
        if ! validate_repo "$REPO_SLUG"; then
            print_error "Must be in the form USER/REPO"
            REPO_SLUG=""
        fi
    done
fi

if ! validate_author_folder "$AUTHOR_FOLDER"; then
    print_error "Invalid author folder: $AUTHOR_FOLDER (must be snake_case)"
    exit 1
fi
if ! validate_repo "$REPO_SLUG"; then
    print_error "Invalid repository: $REPO_SLUG (must be USER/REPO)"
    exit 1
fi

MAINTAINER="${PARAM_MAINTAINER:-${REPO_SLUG%%/*}}"

# ── Summary and confirmation ─────────────────────────────────────────────────

print_header "Configuration"
printf "  %-20s %s\n" "Collection title:" "$COLLECTION_TITLE"
printf "  %-20s %s\n" "Author folder:" "$AUTHOR_FOLDER"
printf "  %-20s %s\n" "Repository:" "$REPO_SLUG"
printf "  %-20s %s\n" "Maintainer:" "$MAINTAINER"
echo ""
print_info "Blueprints will live in:"
print_step "blueprints/automation/${AUTHOR_FOLDER}/"
print_step "blueprints/script/${AUTHOR_FOLDER}/"
print_step "blueprints/template/${AUTHOR_FOLDER}/"

if [[ "$DRY_RUN" == true ]]; then
    echo ""
    print_warning "DRY RUN - no files will be modified"
fi

if [[ "$FORCE" != true && "$DRY_RUN" != true ]]; then
    echo ""
    read -r -p "$(printf "%bProceed?%b [y/N] " "$BOLD" "$NC")" -n 1 reply
    echo ""
    [[ "$reply" =~ ^[Yy]$ ]] || {
        print_info "Cancelled"
        exit 0
    }
fi

# ── File collection ──────────────────────────────────────────────────────────
#
# Files that must KEEP pointing at the upstream template: the sync workflow
# needs the source repo path, and the workflow guards use the upstream slug to
# skip themselves when running inside the template itself.
readonly -a KEEP_UPSTREAM=(
    "./.templatesyncignore"
    "./.github/workflows/template-sync.yml"
    "./.github/workflows/release-please.yml"
)

keeps_upstream() {
    local candidate="$1" keep
    for keep in "${KEEP_UPSTREAM[@]}"; do
        [[ "$candidate" == "$keep" ]] && return 0
    done
    return 1
}

collect_files() {
    find . -type f \
        -not -path "./.git/*" \
        -not -path "./node_modules/*" \
        -not -path "./config/*" \
        -not -path "./.local/*" \
        -not -path "./.venv/*" \
        -not -path "./.ruff_cache/*" \
        -not -path "./.pytest_cache/*" \
        -not -path "./.ai-scratch/*" \
        -not -name "initialize.sh" \
        -not -name "*.lock" \
        -not -name "package-lock.json" \
        -not -name "LICENSE" \
        -print0
}

# ── Apply ────────────────────────────────────────────────────────────────────

print_header "Applying configuration"

# 1. Rename the author folders
for domain in automation script template; do
    src="blueprints/${domain}/${TPL_AUTHOR_FOLDER}"
    dest="blueprints/${domain}/${AUTHOR_FOLDER}"
    [[ -d "$src" ]] || continue
    if [[ "$src" == "$dest" ]]; then
        print_step "blueprints/${domain}/: already named ${AUTHOR_FOLDER}"
        continue
    fi
    if [[ "$DRY_RUN" == true ]]; then
        print_step "Would rename: $src → $dest"
    else
        mv "$src" "$dest"
        print_step "Renamed: $src → $dest"
    fi
done

# 2. Replace placeholders in file contents
replaced_count=0
while IFS= read -r -d '' file; do
    # Skip binary files
    grep -Iq . "$file" 2>/dev/null || continue

    changed=false
    content=$(cat "$file")
    original="$content"

    content="${content//${TPL_AUTHOR_FOLDER}/${AUTHOR_FOLDER}}"
    content="${content//${TPL_TITLE}/${COLLECTION_TITLE}}"

    if ! keeps_upstream "$file"; then
        content="${content//${TPL_REPO}/${REPO_SLUG}}"
        content="${content//jpawlowski\/ha.blueprint_collection/${REPO_SLUG}}"
        content="${content//%40jpawlowski/%40${MAINTAINER}}"
    fi

    [[ "$content" != "$original" ]] && changed=true

    if [[ "$changed" == true ]]; then
        replaced_count=$((replaced_count + 1))
        if [[ "$DRY_RUN" == true ]]; then
            print_step "Would update: ${file#./}"
        else
            printf '%s\n' "$content" >"$file"
        fi
    fi
done < <(collect_files)

if [[ "$DRY_RUN" != true ]]; then
    print_step "Updated $replaced_count file(s)"
fi

# 3. Swap in the collection README
if [[ -f "README.template.md" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        print_step "Would replace README.md with README.template.md"
    else
        mv "README.template.md" "README.md"
        print_step "README.md replaced with the collection README"
    fi
fi

# 4. Reset the release version
if [[ -f ".release-please-manifest.json" && "$DRY_RUN" != true ]]; then
    printf '{\n  ".": "0.1.0"\n}\n' >".release-please-manifest.json"
    print_step "Reset version to 0.1.0"
fi

# 5. Remove the upstream syncs
#
# The collection template pulls its shared development environment from the
# upstream integration blueprint, and vendored agent-skill material from
# third-party skill repositories. Your repository does neither: it syncs from
# the collection template via .github/workflows/template-sync.yml, which
# already carries all of those files along. Keeping these syncs here would mean
# unrelated repositories opening pull requests against yours.
#
# script/skills-sync is kept — it still verifies the vendored files you
# received, and restores one if it gets edited by accident.
readonly -a UPSTREAM_SYNC_FILES=(
    ".github/workflows/chassis-sync.yml"
    ".github/chassis-manifest.txt"
    "script/chassis-sync"
    ".github/workflows/skills-sync.yml"
)
for upstream_sync_file in "${UPSTREAM_SYNC_FILES[@]}"; do
    [[ -e "$upstream_sync_file" ]] || continue
    if [[ "$DRY_RUN" == true ]]; then
        print_step "Would remove: $upstream_sync_file"
    else
        rm -f "$upstream_sync_file"
        print_step "Removed: $upstream_sync_file"
    fi
done

# ── Finish ───────────────────────────────────────────────────────────────────

if [[ "$DRY_RUN" == true ]]; then
    print_header "Dry run complete"
    print_info "No files were modified. Re-run without --dry-run to apply."
    exit 0
fi

# Self-delete
rm -f "$0"

print_header "✨ Initialization complete"
print_success "Your collection is ready: $COLLECTION_TITLE"
echo ""
print_info "Next steps:"
print_step "1. ${BOLD}./script/blueprint-check${NC}  — verify the example blueprints and their source_urls"
print_step "2. ${BOLD}./script/test${NC}             — run the runtime test suite"
print_step "3. ${BOLD}./script/develop${NC}          — start Home Assistant and try a blueprint in the UI"
echo ""
print_info "Then write your first blueprint:"
print_step "blueprints/automation/${AUTHOR_FOLDER}/<name>.yaml"
print_step "See docs/development/AUTHORING.md for the rules."
echo ""
print_info "Regenerate the README import badges any time with:"
print_step "${BOLD}./script/import-links${NC}"
echo ""
print_warning "Review the changes with 'git diff' before committing."
echo ""
