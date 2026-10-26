#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# ARAS Workspace - Terminal Intro Animation
# Dynamic version - fetches data from GitHub API
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION - Edit these values
# ═══════════════════════════════════════════════════════════════════════════

# GitHub
GITHUB_ORG="ARAS-Workspace"

# Excluded repositories
specialExcludedRepos=(".github")

# Domain & SSH
DOMAIN="aras.tc"
SSH_USER="workspace"
SSH_HOST="aras"
GUEST_USER="guest"
GUEST_HOST="local"

# Branding
AUTHOR_NAME="Rıza Emre ARAS"
AUTHOR_EMAIL="r.emrearas@proton.me"

# ASCII Art Banner (no leading whitespace for proper alignment)
ASCII_BANNER='
  █████╗ ██████╗  █████╗ ███████╗
 ██╔══██╗██╔══██╗██╔══██╗██╔════╝
 ███████║██████╔╝███████║███████╗
 ██╔══██║██╔══██╗██╔══██║╚════██║
 ██║  ██║██║  ██║██║  ██║███████║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
'

# Animation Timing
TYPING_SPEED=0.05
TYPING_VARIANCE=0.03
COMMAND_PAUSE=0.4
LINE_PAUSE=0.2
SECTION_PAUSE=1.2

# Colors
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_GREEN='\033[32m'
C_CYAN='\033[36m'
C_YELLOW='\033[33m'

# ═══════════════════════════════════════════════════════════════════════════
# GITHUB API FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════



fetch_repositories() {
    local repos
    local jq_filter
    local auth_header=()

    # Build jq filter from excluded repos array
    jq_filter=$(printf '"%s",' "${specialExcludedRepos[@]}")
    jq_filter="[${jq_filter%,}]"

    # Authenticate when a token is available (avoids shared runner rate limits)
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        auth_header=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    fi

    # Sorted by star count (desc); ties keep API order (most recently updated first)
    # Output: <name>\t<ls -l style date> (recent: "Oct 26 17:20", older than 6 months: "Oct 26  2025")
    repos=$(curl -sf ${auth_header[@]+"${auth_header[@]}"} \
            "https://api.github.com/orgs/${GITHUB_ORG}/repos?type=public&sort=updated&per_page=100" | \
            jq -r --argjson excluded "$jq_filter" \
            '[.[] | select(.name as $n | $excluded | index($n) | not)] | sort_by(-.stargazers_count) | .[] |
             (.updated_at | fromdate) as $t |
             "\(.name)\t\($t | strftime(if (now - $t) > 15552000 then "%b %e  %Y" else "%b %e %H:%M" end))"')

    echo "$repos"
}

# ═══════════════════════════════════════════════════════════════════════════
# ANIMATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

type_text() {
    local text="$1"
    local speed="${2:-$TYPING_SPEED}"

    for ((i=0; i<${#text}; i++)); do
        printf '%s' "${text:$i:1}"
        local variance
        variance=$(printf "%.3f" "$(echo "scale=3; ($RANDOM % 100) * $TYPING_VARIANCE / 100" | bc)")
        sleep "$(echo "$speed + $variance" | bc)"
    done
}

type_command() {
    local prompt="$1"
    local command="$2"
    local output="$3"

    printf '%b' "$prompt"
    sleep 0.2
    type_text "$command"
    sleep "$COMMAND_PAUSE"
    printf '\n'

    if [[ -n "$output" ]]; then
        sleep 0.15
        printf '%b' "$output"
        [[ "$output" != *$'\n' ]] && printf '\n'
    fi

    sleep "$LINE_PAUSE"
}

instant() {
    printf '%b' "$1"
}

progress_dots() {
    local message="$1"
    local count="${2:-3}"

    printf '%s' "$message"
    for ((i=0; i<count; i++)); do
        sleep 0.3
        printf '.'
    done
    printf '\n'
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN ANIMATION
# ═══════════════════════════════════════════════════════════════════════════

main() {
    # ─────────────────────────────────────────────────────────
    # Fetch dynamic data from GitHub API
    # ─────────────────────────────────────────────────────────

    echo "Fetching data from GitHub API..." >&2

    local repos_raw
    repos_raw=$(fetch_repositories)

    # Format repos for display (ls -l style, one per line, read-only)
    local repos_display=""
    local repo_count=0
    local repo updated
    while IFS=$'\t' read -r repo updated; do
        [[ -z "$repo" ]] && continue
        repos_display+="\n${C_DIM}dr-xr-xr-x 2 ${SSH_USER} ${SSH_USER} ${updated}${C_RESET} ${C_YELLOW}${repo}${C_RESET}"
        repo_count=$((repo_count + 1))
    done <<< "$repos_raw"
    repos_display="total $((repo_count * 4))${repos_display}"

    echo "Data fetched. Starting animation..." >&2
    sleep 1

    # ─────────────────────────────────────────────────────────
    # Animation Start
    # ─────────────────────────────────────────────────────────

    clear
    sleep 0.5

    # ═══════════════════════════════════════════════════════
    # PHASE 1: SSH Connection
    # ═══════════════════════════════════════════════════════

    local guest_prompt="${C_GREEN}${GUEST_USER}${C_RESET}@${C_CYAN}${GUEST_HOST}${C_RESET}:~\$ "

    printf '%b' "$guest_prompt"
    sleep 0.2
    type_text "ssh ${SSH_USER}@${DOMAIN}"
    sleep "$COMMAND_PAUSE"
    printf '\n'

    sleep 0.4
    progress_dots "Connecting to ${DOMAIN}"
    sleep 0.2

    instant "${C_DIM}Authenticating...${C_RESET}\n"
    sleep 0.5

    instant "${C_GREEN}Connection established.${C_RESET}\n"
    sleep "$SECTION_PAUSE"

    clear
    sleep 0.3

    local ws_prompt="${C_GREEN}${SSH_USER}${C_RESET}@${C_CYAN}${SSH_HOST}${C_RESET}:~\$ "

    # ═══════════════════════════════════════════════════════
    # PHASE 2: Welcome Banner
    # ═══════════════════════════════════════════════════════

    type_command "$ws_prompt" "cat /etc/motd" "${C_BOLD}${ASCII_BANNER}${C_RESET}"

    sleep "$SECTION_PAUSE"

    # ═══════════════════════════════════════════════════════
    # PHASE 3: Interactive Session
    # ═══════════════════════════════════════════════════════

    # Command: whoami
    type_command "$ws_prompt" "whoami" "${C_BOLD}${AUTHOR_NAME}${C_RESET} ${C_DIM}<${AUTHOR_EMAIL}>${C_RESET}"

    sleep 0.6

    # Command: pwd
    type_command "$ws_prompt" "pwd" "/home/${C_CYAN}${GITHUB_ORG}${C_RESET}"

    sleep 0.6

    # Command: ls -l projects (dynamic from API)
    type_command "$ws_prompt" "ls -l projects/" "$repos_display"

    sleep "$SECTION_PAUSE"

    # ═══════════════════════════════════════════════════════
    # PHASE 4: Final prompt with blinking cursor
    # ═══════════════════════════════════════════════════════

    printf '%b' "$ws_prompt"
    sleep 2

    printf '\n'
    sleep 0.5
}

# ═══════════════════════════════════════════════════════════════════════════
# RUN
# ═══════════════════════════════════════════════════════════════════════════

main "$@"
