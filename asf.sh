#!/bin/bash

# Define variables
SESSION_NAME="asf" # tmux session name
ASF_CONFIG_DIR="/home/asf/config" # Path to ASF config directory

# Check if tmux session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null
if [ $? != 0 ]; then
    echo "No existing tmux session found. Starting a new session..."

    # Start a new tmux session and run the ArchiSteamFarm process in it
    tmux new-session -d -s "$SESSION_NAME"
    tmux send-keys -t "$SESSION_NAME" "docker run -d -p 0.0.0.0:1242:1242 -p [::1]:1242:1242 -v $ASF_CONFIG_DIR:/app/config --name asf --pull always justarchi/archisteamfarm" C-m

    echo "ArchiSteamFarm process started in new tmux session."
else
    echo "Tmux session found. Restarting ArchiSteamFarm process..."

    # Kill the current ArchiSteamFarm process running in tmux
    tmux send-keys -t "$SESSION_NAME" C-c # Send Ctrl+C to stop current process
    sleep 2  # Give it a couple of seconds to stop

    # Restart the ArchiSteamFarm process
    tmux send-keys -t "$SESSION_NAME" "docker run -d -p 0.0.0.0:1242:1242 -p [::1]:1242:1242 -v $ASF_CONFIG_DIR:/app/config --name asf --pull always justarchi/archisteamfarm" C-m

    echo "ArchiSteamFarm process restarted in tmux session."
fi

echo "ArchiSteamFarm script execution completed."