#!/usr/bin/env python3
"""Lista imagens locais e persiste a seleção; nunca invoca um shell."""
import json, os, sys
from pathlib import Path
state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home()/".local/state"))) / "brise/wallpaper.json"
def current():
    try: return json.loads(state.read_text()).get("path", "")
    except (OSError, ValueError): return ""
if sys.argv[1] == "current":
    print(current())
elif sys.argv[1] == "save":
    image = Path(sys.argv[2])
    if not image.is_file(): raise SystemExit(1)
    state.parent.mkdir(parents=True, exist_ok=True)
    tmp = state.with_suffix(".tmp")
    tmp.write_text(json.dumps({"path": str(image)}, ensure_ascii=False))
    tmp.replace(state)
elif sys.argv[1] == "list":
    folders = [Path(sys.argv[2]), Path.home()/"Pictures/Wallpapers", Path.home()/"Imagens/Wallpapers"]
    images = set()
    for folder in folders:
        if folder.is_dir():
            images.update(str(f) for f in folder.rglob("*") if f.is_file() and f.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"})
    print(json.dumps({"files": sorted(images), "current": current()}, ensure_ascii=False))
