#!/bin/bash

# Define variables
SESSION_NAME="hastebin" # tmux session name
HASTEBIN_DIR="haste-server/" # Path to Hastebin directory

# Navigate to the Hastebin directory
cd "$HASTEBIN_DIR" || { echo "Failed to navigate to Hastebin directory. Exiting..."; exit 1; }

# Check if tmux session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null
if [ $? != 0 ]; then
    echo "No existing tmux session found. Starting a new session..."

    # Start a new tmux session and run the Hastebin process in it
    tmux new-session -d -s "$SESSION_NAME"
    tmux send-keys -t "$SESSION_NAME" "npm start" C-m

    echo "Hastebin process started in new tmux session."
else
    echo "Tmux session found. Restarting Hastebin process..."

    # Kill the current Hastebin process running in tmux
    tmux send-keys -t "$SESSION_NAME" C-c # Send Ctrl+C to stop current process
    sleep 2  # Give it a couple of seconds to stop

    # Restart the Hastebin process
    tmux send-keys -t "$SESSION_NAME" "npm start" C-m

    echo "Hastebin process restarted in tmux session."
fi

echo "Hastebin script execution completed."