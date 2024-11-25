#!/bin/bash

# Steam Backup Script
# Base configuration variables
# To get your Steam API key:
# 1. Visit: https://steamcommunity.com/dev/apikey
# 2. Log in with your Steam account
# 3. Enter a domain name (can be anything if for personal use)
# 4. Your API key will be generated and displayed
STEAM_API_KEY=""
STEAM_USERNAME=""
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_BASE_DIR="$HOME/steam_backups"

# Steam installation directories for different platforms
STEAM_INSTALL_DIR_LINUX="$HOME/.local/share/Steam"
STEAM_INSTALL_DIR_MACOS="$HOME/Library/Application Support/Steam"
STEAM_INSTALL_DIR_DECK="$HOME/.local/share/Steam"

# OS Detection function
get_os() {
    case "$(uname -s)" in
        Linux*)
            if [ -f /etc/os-release ]; then
                if grep -q "SteamOS" /etc/os-release; then
                    echo "steamdeck"
                else
                    echo "linux"
                fi
            else
                echo "linux"
            fi
            ;;
        Darwin*)    echo "macos" ;;
        *)         echo "unknown" ;;
    esac
}

# Convert SteamID64 to local ID
get_local_id() {
    local steamid64=$1
    local base=76561197960265728
    echo $((steamid64 - base))
}

# Get Steam ID using Web API and calculate local ID
get_steam_id() {
    if [ -z "$STEAM_USERNAME" ]; then
        echo "Error: Steam username is required!"
        exit 1
    fi

    echo "Fetching Steam ID for user: $STEAM_USERNAME"
    steam_id=$(curl -s "http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=$STEAM_API_KEY&vanityurl=$STEAM_USERNAME" | grep -o '"steamid":"[0-9]*"' | cut -d'"' -f4)
    
    if [ -z "$steam_id" ]; then
        echo "Error: Could not find Steam ID for username $STEAM_USERNAME"
        exit 1
    fi

    local_id=$(get_local_id $steam_id)
    echo "Found user: $STEAM_USERNAME"
    echo "Local ID: $local_id"
    echo
    
    backup_dir="${BACKUP_BASE_DIR}/steam_backup_${TIMESTAMP}_${steam_id}_${local_id}"
}

linux_backup() {
    get_steam_id
    
    echo "Creating backup directories..."
    mkdir -p "$backup_dir"/{clientui,config,userdata,skins,cloud_saves}
    echo "Created directory structure at: $backup_dir"
    echo
    
    echo "Backing up Steam files..."
    echo "=========================================="
    
    echo "Backing up Client UI preferences..."
    cp -r "$STEAM_INSTALL_DIR_LINUX/clientui/"* "$backup_dir/clientui/"
    echo "Client UI backup complete"
    echo
    
    echo "Backing up Global Steam configs..."
    cp "$STEAM_INSTALL_DIR_LINUX/config/config.vdf" "$backup_dir/config/"
    cp "$STEAM_INSTALL_DIR_LINUX/config/loginusers.vdf" "$backup_dir/config/"
    cp "$STEAM_INSTALL_DIR_LINUX/config/dialogconfig.vdf" "$backup_dir/config/"
    echo "Global configs backup complete"
    echo
    
    echo "Backing up User Data..."
    cp "$STEAM_INSTALL_DIR_LINUX/userdata/$local_id/config/localconfig.vdf" "$backup_dir/userdata/"
    cp "$STEAM_INSTALL_DIR_LINUX/userdata/$local_id/7/remote/sharedconfig.vdf" "$backup_dir/userdata/"
    cp "$STEAM_INSTALL_DIR_LINUX/userdata/$local_id/760/screenshots.vdf" "$backup_dir/userdata/"
    cp "$STEAM_INSTALL_DIR_LINUX/userdata/$local_id/config/shortcuts.vdf" "$backup_dir/userdata/"
    cp -r "$STEAM_INSTALL_DIR_LINUX/userdata/$local_id/241100" "$backup_dir/userdata/"
    cp -r "$STEAM_INSTALL_DIR_LINUX/userdata/$local_id/config/controller_configs" "$backup_dir/userdata/"
    cp -r "$STEAM_INSTALL_DIR_LINUX/userdata/$local_id/7/remote" "$backup_dir/userdata/collections"
    echo "User data backup complete"
    echo
    
    echo "Backing up Steam Skins..."
    cp -r "$STEAM_INSTALL_DIR_LINUX/skins" "$backup_dir/skins/"
    echo "Skins backup complete"
    echo
    
    echo "Backing up Cloud Saves..."
    find "$STEAM_INSTALL_DIR_LINUX/userdata/$local_id" -name "remote" -type d -exec cp -r {} "$backup_dir/cloud_saves/" \;
    echo "Cloud saves backup complete"
    echo
    
    echo "=========================================="
    echo "Backup completed successfully!"
    echo
    echo "Files saved to: $backup_dir"
    echo
}

deck_backup() {
    get_steam_id
    
    echo "Creating backup directories..."
    mkdir -p "$backup_dir"/{clientui,config,userdata,skins,cloud_saves}
    echo "Created directory structure at: $backup_dir"
    echo
    
    echo "Backing up Steam files..."
    echo "=========================================="
    
    echo "Backing up Client UI preferences..."
    cp -r "$STEAM_INSTALL_DIR_DECK/clientui/"* "$backup_dir/clientui/"
    echo "Client UI backup complete"
    echo
    
    echo "Backing up Global Steam configs..."
    cp "$STEAM_INSTALL_DIR_DECK/config/config.vdf" "$backup_dir/config/"
    cp "$STEAM_INSTALL_DIR_DECK/config/loginusers.vdf" "$backup_dir/config/"
    cp "$STEAM_INSTALL_DIR_DECK/config/dialogconfig.vdf" "$backup_dir/config/"
    echo "Global configs backup complete"
    echo
    
    echo "Backing up User Data..."
    cp "$STEAM_INSTALL_DIR_DECK/userdata/$local_id/config/localconfig.vdf" "$backup_dir/userdata/"
    cp "$STEAM_INSTALL_DIR_DECK/userdata/$local_id/7/remote/sharedconfig.vdf" "$backup_dir/userdata/"
    cp "$STEAM_INSTALL_DIR_DECK/userdata/$local_id/760/screenshots.vdf" "$backup_dir/userdata/"
    cp "$STEAM_INSTALL_DIR_DECK/userdata/$local_id/config/shortcuts.vdf" "$backup_dir/userdata/"
    cp -r "$STEAM_INSTALL_DIR_DECK/userdata/$local_id/241100" "$backup_dir/userdata/"
    cp -r "$STEAM_INSTALL_DIR_DECK/userdata/$local_id/config/controller_configs" "$backup_dir/userdata/"
    cp -r "$STEAM_INSTALL_DIR_DECK/userdata/$local_id/7/remote" "$backup_dir/userdata/collections"
    echo "User data backup complete"
    echo
    
    echo "Backing up Steam Skins..."
    cp -r "$STEAM_INSTALL_DIR_DECK/skins" "$backup_dir/skins/"
    echo "Skins backup complete"
    echo
    
    echo "Backing up Cloud Saves..."
    find "$STEAM_INSTALL_DIR_DECK/userdata/$local_id" -name "remote" -type d -exec cp -r {} "$backup_dir/cloud_saves/" \;
    echo "Cloud saves backup complete"
    echo
    
    echo "=========================================="
    echo "Backup completed successfully!"
    echo
    echo "Files saved to: $backup_dir"
    echo
}

macos_backup() {
    get_steam_id
    
    echo "Creating backup directories..."
    mkdir -p "$backup_dir"/{clientui,config,userdata,skins,cloud_saves}
    echo "Created directory structure at: $backup_dir"
    echo
    
    echo "Backing up Steam files..."
    echo "=========================================="
    
    echo "Backing up Client UI preferences..."
    cp -r "$STEAM_INSTALL_DIR_MACOS/clientui/"* "$backup_dir/clientui/"
    echo "Client UI backup complete"
    echo
    
    echo "Backing up Global Steam configs..."
    cp "$STEAM_INSTALL_DIR_MACOS/config/config.vdf" "$backup_dir/config/"
    cp "$STEAM_INSTALL_DIR_MACOS/config/loginusers.vdf" "$backup_dir/config/"
    cp "$STEAM_INSTALL_DIR_MACOS/config/dialogconfig.vdf" "$backup_dir/config/"
    echo "Global configs backup complete"
    echo
    
    echo "Backing up User Data..."
    cp "$STEAM_INSTALL_DIR_MACOS/userdata/$local_id/config/localconfig.vdf" "$backup_dir/userdata/"
    cp "$STEAM_INSTALL_DIR_MACOS/userdata/$local_id/7/remote/sharedconfig.vdf" "$backup_dir/userdata/"
    cp "$STEAM_INSTALL_DIR_MACOS/userdata/$local_id/760/screenshots.vdf" "$backup_dir/userdata/"
    cp "$STEAM_INSTALL_DIR_MACOS/userdata/$local_id/config/shortcuts.vdf" "$backup_dir/userdata/"
    cp -r "$STEAM_INSTALL_DIR_MACOS/userdata/$local_id/241100" "$backup_dir/userdata/"
    cp -r "$STEAM_INSTALL_DIR_MACOS/userdata/$local_id/config/controller_configs" "$backup_dir/userdata/"
    cp -r "$STEAM_INSTALL_DIR_MACOS/userdata/$local_id/7/remote" "$backup_dir/userdata/collections"
    echo "User data backup complete"
    echo
    
    echo "Backing up Steam Skins..."
    cp -r "$STEAM_INSTALL_DIR_MACOS/skins" "$backup_dir/skins/"
    echo "Skins backup complete"
    echo
    
    echo "Backing up Cloud Saves..."
    find "$STEAM_INSTALL_DIR_MACOS/userdata/$local_id" -name "remote" -type d -exec cp -r {} "$backup_dir/cloud_saves/" \;
    echo "Cloud saves backup complete"
    echo
    
    echo "=========================================="
    echo "Backup completed successfully!"
    echo
    echo "Files saved to: $backup_dir"
    echo
}

# Detect OS and show appropriate menu
current_os=$(get_os)

echo "Steam Backup Script"
echo "=========================================="
echo

case "$current_os" in
    "linux")
        echo "Detected OS: Linux"
        echo "1. Linux Backup"
        read -p "Press 1 to continue: " choice
        [[ $choice == "1" ]] && linux_backup || echo "Invalid choice"
        ;;
    "steamdeck")
        echo "Detected OS: Steam Deck"
        echo "1. Steam Deck Backup"
        read -p "Press 1 to continue: " choice
        [[ $choice == "1" ]] && deck_backup || echo "Invalid choice"
        ;;
    "macos")
        echo "Detected OS: macOS"
        echo "1. macOS Backup"
        read -p "Press 1 to continue: " choice
        [[ $choice == "1" ]] && macos_backup || echo "Invalid choice"
        ;;
    *)
        echo "Unsupported operating system"
        exit 1
        ;;
esac

echo "Press Enter to exit..."
read