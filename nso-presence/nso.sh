nso() {
  if pgrep -f "nxapi nso presence" >/dev/null; then
    echo "Nintendo Switch Online Presence is already running."
    return 0
  fi
  mkdir -p ~/.local/state
  nohup npx nxapi nso presence > ~/.local/state/nxapi-presence.log 2>&1 &
  sleep 5
  if pgrep -f "nxapi nso presence" >/dev/null; then
    echo "Nintendo Switch Online Presence daemon is running."
  else
    echo "Start failed, see ~/.local/state/nxapi-presence.log"
    tail -n 10 ~/.local/state/nxapi-presence.log
  fi
}

nso-stop() {
  pkill -f "nxapi nso presence" && echo "Stopped." || echo "Was not running."
}
