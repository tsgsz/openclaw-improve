#!/bin/zsh
set -euo pipefail

LABEL="com.openclaw.autossh-tunnels"
UID_NUM=$(id -u)
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
SCRIPT="$HOME/.openclaw/bin/openclaw-tunnels.sh"
LOG_OUT="$HOME/.openclaw/logs/autossh-tunnels.out.log"
LOG_ERR="$HOME/.openclaw/logs/autossh-tunnels.err.log"
KEY="$HOME/.ssh/openclaw_aliyun_ed25519"
VPS_USER="tsgsz"
VPS_HOST="39.106.62.105"

usage() {
  cat <<EOF
Usage: tunnelsctl.zsh <cmd>

cmd:
  where    Print key paths
  status   Show LaunchAgent status + VPS listening ports
  start    Bootstrap + enable + kickstart LaunchAgent
  restart  Kickstart LaunchAgent (force restart)
  stop     Bootout/unload LaunchAgent
  logs     Tail logs (out+err)
EOF
}

cmd=${1:-}
case "$cmd" in
  where)
    echo "LABEL:   $LABEL"
    echo "PLIST:   $PLIST"
    echo "SCRIPT:  $SCRIPT"
    echo "KEY:     $KEY"
    echo "LOG_OUT: $LOG_OUT"
    echo "LOG_ERR: $LOG_ERR"
    echo "VPS:     ${VPS_USER}@${VPS_HOST}"
    ;;

  status)
    echo "== launchctl print =="
    launchctl print "gui/${UID_NUM}/${LABEL}" 2>/dev/null | sed -n '1,120p' || echo "(not loaded)"
    echo
    echo "== local ssh processes =="
    ps aux | grep -E "(autossh|ssh).*openclaw_vps_ed25519" | grep -v grep || true
    echo
    echo "== VPS listeners (2222 + 18789) =="
    if [ -f "$KEY" ]; then
      ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=6 "${VPS_USER}@${VPS_HOST}" \
        "ss -lntp | egrep ':2222 |:18789 ' || true" || true
    else
      echo "(missing key: $KEY)"
    fi
    ;;

  start)
    if [ ! -f "$PLIST" ]; then
      echo "Missing plist: $PLIST" >&2
      exit 1
    fi
    launchctl bootstrap "gui/${UID_NUM}" "$PLIST"
    launchctl enable "gui/${UID_NUM}/${LABEL}" || true
    launchctl kickstart -k "gui/${UID_NUM}/${LABEL}"
    ;;

  restart)
    launchctl kickstart -k "gui/${UID_NUM}/${LABEL}"
    ;;

  stop)
    launchctl bootout "gui/${UID_NUM}/${LABEL}" || true
    ;;

  logs)
    echo "== tail out =="
    ( [ -f "$LOG_OUT" ] && tail -n 80 -f "$LOG_OUT" ) &
    OUTPID=$!
    echo "== tail err =="
    ( [ -f "$LOG_ERR" ] && tail -n 80 -f "$LOG_ERR" ) &
    ERRPID=$!
    trap 'kill $OUTPID $ERRPID 2>/dev/null || true' INT TERM EXIT
    wait
    ;;

  *)
    usage
    exit 2
    ;;
esac
