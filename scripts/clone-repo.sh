#!/usr/bin/env bash
#
# clone-repo.sh - Interactive GitHub repository cloner with fzf
# Binds to Ctrl+G for quick access to clone repositories
#

set -euo pipefail

# Find the correct TTY for input (needed when called from bind -x in tmux)
if [[ -n "${TMUX:-}" ]]; then
    TTY_INPUT=$(tmux list-panes -F "#{pane_tty}" 2>/dev/null | head -1)
else
    TTY_INPUT="/dev/tty"
fi

# Fallback if TTY not found
if [[ ! -e "$TTY_INPUT" ]]; then
    TTY_INPUT="/dev/tty"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/clone-repo"
CONFIG_FILE="$CONFIG_DIR/config"
CACHE_FILE="$CONFIG_DIR/cache.json"
CACHE_TTL=3600 # Cache time-to-live in seconds (1 hour)

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Function to print colored messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Helper function to read from TTY properly
read_from_tty() {
    local prompt="$1"
    local var_name="$2"
    local default="${3:-}"

    # Save terminal state and set to sane mode
    local saved_settings=""
    if [[ -t 0 ]]; then
        saved_settings=$(stty -g 2>/dev/null || true)
    fi

    # Disable bracketed paste mode to avoid escape sequences
    printf '\e[?2004l' > "$TTY_INPUT" 2>/dev/null || true

    # Ensure terminal is in canonical mode for proper input
    stty sane 2>/dev/null || true
    stty echo 2>/dev/null || true

    # Read from TTY
    exec 3<>"$TTY_INPUT"
    read -rp "$prompt" "$var_name" <&3
    exec 3>&-

    # Restore terminal state
    if [[ -n "$saved_settings" ]]; then
        stty "$saved_settings" 2>/dev/null || true
    fi

    # Clean bracketed paste escape sequences from input
    local cleaned_value="${!var_name}"
    cleaned_value="${cleaned_value//$'\x1b[200~'/}"
    cleaned_value="${cleaned_value//$'\x1b[201~'/}"
    cleaned_value="${cleaned_value//\[\[200~/}"
    cleaned_value="${cleaned_value//\[\[201~/}"
    eval "$var_name='$cleaned_value'"

    # Apply default if empty
    if [[ -n "$default" && -z "${!var_name}" ]]; then
        eval "$var_name='$default'"
    fi
}

# Function to validate GitHub token
validate_token() {
    local token="$1"

    local response
    response=$(curl -s -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user" 2>/dev/null)

    # Check if token is valid - successful response will have "login" field
    if echo "$response" | jq -e '.login' > /dev/null 2>&1; then
        local username
        username=$(echo "$response" | jq -r '.login')
        log_success "Authenticated as: $username"
        return 0
    else
        local error_msg
        error_msg=$(echo "$response" | jq -r '.message // "Unknown error"' 2>/dev/null)
        log_error "Invalid token: $error_msg"
        return 1
    fi
}

# Function to get GitHub token
get_github_token() {
    local token=""

    # Try to read from config file
    if [[ -f "$CONFIG_FILE" ]]; then
        token=$(grep -E '^GITHUB_TOKEN=' "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi

    # Try environment variable
    if [[ -z "$token" && -n "${GITHUB_TOKEN:-}" ]]; then
        token="$GITHUB_TOKEN"
    fi

    # Try git config
    if [[ -z "$token" ]]; then
        token=$(git config --global github.token 2>/dev/null || echo "")
    fi

    echo "$token"
}

# Function to create config file
create_config() {
    local force="${1:-false}"

    if [[ "$force" == "false" ]]; then
        log_info "GitHub token not found. Let's set it up!"
    else
        log_info "Let's update your GitHub token!"
    fi
    echo ""
    echo "You can create a personal access token at:"
    echo "https://github.com/settings/tokens/new"
    echo ""
    echo "Required scopes: repo (for private repos) or public_repo (for public only)"
    echo ""

    local token=""
    while true; do
        read_from_tty "Enter your GitHub personal access token: " token
        echo ""

        if [[ -z "$token" ]]; then
            log_error "Token cannot be empty"
            continue
        fi

        # Validate token before saving
        if validate_token "$token"; then
            break
        else
            echo ""
            read_from_tty "Try again? [Y/n]: " retry "Y"
            if [[ ! "$retry" =~ ^[Yy]$ ]]; then
                return 1
            fi
            echo ""
        fi
    done

    # Save token to config file (preserve other settings if updating)
    if [[ "$force" == "true" && -f "$CONFIG_FILE" ]]; then
        # Update existing config, preserve CLONE_DIR and GITHUB_USER
        local clone_dir
        local github_user
        clone_dir=$(grep -E '^CLONE_DIR=' "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2-)
        github_user=$(grep -E '^GITHUB_USER=' "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2-)

        cat > "$CONFIG_FILE" << EOF
# GitHub Personal Access Token
# Get yours at: https://github.com/settings/tokens
GITHUB_TOKEN="$token"

# Default clone directory (leave empty to use current directory)
CLONE_DIR="${clone_dir:-}"

# GitHub username (optional, for filtering repos)
GITHUB_USER="${github_user:-}"
EOF
    else
        cat > "$CONFIG_FILE" << EOF
# GitHub Personal Access Token
# Get yours at: https://github.com/settings/tokens
GITHUB_TOKEN="$token"

# Default clone directory (leave empty to use current directory)
CLONE_DIR=""

# GitHub username (optional, for filtering repos)
GITHUB_USER=""
EOF
    fi

    chmod 600 "$CONFIG_FILE"
    log_success "Config file saved at $CONFIG_FILE"
    echo "$token"
}

# Function to check if cache is valid
is_cache_valid() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        return 1
    fi
    
    local cache_time
    cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo "0")
    local current_time
    current_time=$(date +%s)
    local age=$((current_time - cache_time))
    
    if [[ $age -lt $CACHE_TTL ]]; then
        return 0
    else
        return 1
    fi
}

# Function to fetch repositories from GitHub
fetch_repos() {
    local token="$1"
    local page=1
    local per_page=100
    local all_repos="[]"
    
    log_info "Fetching repositories from GitHub..."
    
    while true; do
        local response
        response=$(curl -s -H "Authorization: token $token" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/user/repos?per_page=$per_page&page=$page&affiliation=owner,collaborator,organization_member&sort=updated")
        
        # Check for API errors
        if echo "$response" | grep -q '"message"'; then
            local error_msg
            error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
            log_error "GitHub API error: $error_msg"
            return 1
        fi
        
        # Check if we got any repos
        local repo_count
        repo_count=$(echo "$response" | jq 'length' 2>/dev/null || echo "0")
        
        if [[ $repo_count -eq 0 ]]; then
            break
        fi
        
        # Merge responses
        all_repos=$(echo "$all_repos" "$response" | jq -s 'add')
        
        log_info "Fetched page $page ($repo_count repos)"
        
        if [[ $repo_count -lt $per_page ]]; then
            break
        fi
        
        ((page++))
    done
    
    echo "$all_repos" > "$CACHE_FILE"
    log_success "Fetched $(echo "$all_repos" | jq '. | length') repositories"
}

# Function to format repos for fzf
format_repos_for_fzf() {
    local repos="$1"

    echo "$repos" | jq -r '.[] |
        "\(.full_name)|\(.description // "No description")|\(.ssh_url)|\(.language // "Unknown")"'
}

# Function to clone repository
clone_repository() {
    local repo_info="$1"
    local clone_dir="${2:-.}"

    IFS='|' read -r full_name description git_url language <<< "$repo_info"

    log_info "Cloning: $full_name (SSH)"
    log_info "Description: $description"

    # Extract repo name for directory
    local repo_name
    repo_name=$(basename "$full_name")
    local target_dir="$clone_dir/$repo_name"
    
    # Check if directory already exists
    if [[ -d "$target_dir" ]]; then
        log_warning "Directory $target_dir already exists"
        read_from_tty "Pull latest changes? [Y/n]: " pull_choice "Y"
        
        if [[ "$pull_choice" =~ ^[Yy]$ ]]; then
            cd "$target_dir"
            git pull
            log_success "Updated $full_name"
        fi
    else
        # Clone the repository
        if git clone "$git_url" "$target_dir"; then
            log_success "Cloned $full_name to $target_dir"
        else
            log_error "Failed to clone $full_name"
            return 1
        fi
    fi
}

# Main function
main() {
    # Check for required tools
    for tool in jq fzf curl git; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is not installed. Please install it first."
            return 1
        fi
    done
    
    # Get GitHub token
    local token
    token=$(get_github_token)
    
    if [[ -z "$token" ]]; then
        token=$(create_config) || return 1
    fi
    
    # Check cache or fetch new data
    local repos
    if is_cache_valid; then
        repos=$(cat "$CACHE_FILE")
    else
        if ! fetch_repos "$token"; then
            log_warning "Failed to fetch repositories. Your token may be invalid."
            echo ""
            read_from_tty "Update GitHub token? [Y/n]: " update_token "Y"
            if [[ "$update_token" =~ ^[Yy]$ ]]; then
                token=$(create_config true) || return 1
                # Retry fetching with new token
                fetch_repos "$token" || return 1
                repos=$(cat "$CACHE_FILE")
            else
                return 1
            fi
        else
            repos=$(cat "$CACHE_FILE")
        fi
    fi
    
    # Check if we have any repos
    local repo_count
    repo_count=$(echo "$repos" | jq '. | length')
    
    if [[ $repo_count -eq 0 ]]; then
        log_error "No repositories found"
        return 1
    fi
    
    
    # Format repos for fzf
    local formatted_repos
    formatted_repos=$(format_repos_for_fzf "$repos")
    
    # Show fzf selector
    local selected
    selected=$(echo "$formatted_repos" | \
        fzf --ansi \
            --height=80% \
            --border \
            --preview-window=right:60%:wrap \
            --preview 'echo {} | cut -d"|" -f1,2,4 | sed "s/|/\n/g" | sed "s/^/  /"' \
            --header="Select repository to clone (Ctrl+C to cancel, Ctrl+R to refresh cache)" \
            --prompt="Repo> " \
            --bind "ctrl-r:execute(rm -f $CACHE_FILE)+abort" \
            --delimiter="|" \
            --with-nth=1,2,4)
    
    if [[ -z "$selected" ]]; then
        log_warning "No repository selected"
        return 0
    fi
    
    # Get clone directory from config or use current directory
    local clone_dir="."
    if [[ -f "$CONFIG_FILE" ]]; then
        local config_dir
        config_dir=$(grep -E '^CLONE_DIR=' "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [[ -n "$config_dir" ]]; then
            clone_dir="$config_dir"
        fi
    fi
    
    # Clone the repository
    clone_repository "$selected" "$clone_dir"
}

# Run main function
main "$@"
