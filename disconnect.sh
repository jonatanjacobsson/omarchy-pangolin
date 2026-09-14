#!/usr/bin/env bash
set -euo pipefail

if [[ -x "${HOME}/.local/bin/pangolin" ]]; then
  PANGOLIN="${HOME}/.local/bin/pangolin"
else
  PANGOLIN=$(command -v pangolin)
fi

exec "$PANGOLIN" down
