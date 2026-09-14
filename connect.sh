#!/usr/bin/env bash
# Started as: pkexec /bin/bash connect.sh
# Pangolin's own detached path runs `sudo sh -c 'nohup … &'`. That cannot
# prompt from the bar, and a pkexec-for-sudo shim loses SUDO_USER plus the
# background child when pkexec exits. Run the tunnel as a root systemd unit
# instead so Omarchy's polkit dialog can authorize it and it stays up.
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  exec /usr/bin/pkexec /bin/bash "$(readlink -f "$0")" "$@"
fi

ORIG_UID="${PKEXEC_UID:-}"
if [[ -z "$ORIG_UID" || "$ORIG_UID" == "0" ]]; then
  echo "Pangolin connect must be authorized with pkexec." >&2
  exit 1
fi

ORIG_USER=$(id -nu "$ORIG_UID")
ORIG_HOME=$(getent passwd "$ORIG_UID" | cut -d: -f6)

PANGOLIN=""
for candidate in \
  "$ORIG_HOME/.local/bin/pangolin" \
  /usr/local/bin/pangolin \
  /usr/bin/pangolin
do
  if [[ -x "$candidate" ]]; then
    PANGOLIN="$candidate"
    break
  fi
done

if [[ -z "$PANGOLIN" ]]; then
  echo "pangolin CLI not found" >&2
  exit 1
fi

UNIT=pangolin-olm.service
/usr/bin/systemctl reset-failed "$UNIT" 2>/dev/null || true
if /usr/bin/systemctl is-active --quiet "$UNIT"; then
  exit 0
fi

# PANGOLIN_SUBPROCESS=1 skips Pangolin's inner sudo spawn so this process
# stays in the foreground as the tunnel. SUDO_USER keeps config lookup on
# the user's ~/.config/pangolin instead of /root.
exec /usr/bin/systemd-run \
  --quiet \
  --collect \
  --unit=pangolin-olm \
  --description="Pangolin VPN client" \
  --working-directory="$ORIG_HOME" \
  --setenv=HOME="$ORIG_HOME" \
  --setenv=USER="$ORIG_USER" \
  --setenv=LOGNAME="$ORIG_USER" \
  --setenv=SUDO_USER="$ORIG_USER" \
  --setenv=XDG_CONFIG_HOME="$ORIG_HOME/.config" \
  --setenv=PANGOLIN_SUBPROCESS=1 \
  -- \
  "$PANGOLIN" up --silent
