#!/usr/bin/env bash
set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)
export PATH="$DIR/bin:$PATH"

if [[ -x "${HOME}/.local/bin/pangolin" ]]; then
  PANGOLIN="${HOME}/.local/bin/pangolin"
else
  PANGOLIN=$(command -v pangolin)
fi

exec "$PANGOLIN" up --silent
