#!/usr/bin/env bash
set -euo pipefail

if [[ -x "${HOME}/.local/bin/pangolin" ]]; then
  PANGOLIN="${HOME}/.local/bin/pangolin"
else
  PANGOLIN=$(command -v pangolin)
fi

if "$PANGOLIN" down; then
  exit 0
fi

# The bar starts the tunnel as a root systemd unit. If the API is already
# gone, stop that unit through the same polkit prompt as connect.
if /usr/bin/systemctl is-active --quiet pangolin-olm.service; then
  exec /usr/bin/pkexec /bin/systemctl stop pangolin-olm.service
fi

exit 1
