#!/usr/bin/env bash
set -euo pipefail
brise_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
brise_bin_dir="${BRISE_BIN_DIR:-$HOME/.local/bin}"
mkdir -p -- "$brise_bin_dir"
if [[ -e "$brise_bin_dir/brise" ]]; then
  printf 'O comando já existe: %s\n' "$brise_bin_dir/brise" >&2
  exit 1
fi
printf '#!/usr/bin/env bash\nexec %q "$@"\n' "$brise_dir/brise" > "$brise_bin_dir/brise"
chmod +x "$brise_bin_dir/brise"
printf 'Comando instalado em %s/brise\n' "$brise_bin_dir"
