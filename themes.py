#!/usr/bin/env python3
"""Seleciona uma paleta local com escrita atômica do singleton QML."""
import os
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent
selection = root/'Theme.qml'
command = sys.argv[1] if len(sys.argv) > 1 else 'current'
if command == 'list':
    for folder in sorted((root/'themes').iterdir()):
        if folder.is_dir() and (folder/'Palette.qml').is_file(): print(folder.name)
elif command == 'current':
    match = re.search(r'themes/([A-Za-z0-9_-]+)', selection.read_text()) if selection.exists() else None
    print(match.group(1) if match else 'afeto')
else:
    if not re.fullmatch(r'[A-Za-z0-9_-]+', command) or not (root/'themes'/command/'Palette.qml').is_file():
        print('Tema não encontrado. Use: brise theme list', file=sys.stderr)
        sys.exit(1)
    data = 'pragma Singleton\nimport QtQuick\nimport "themes/' + command + '" as ActiveTheme\n\nActiveTheme.Palette {}\n'
    temporary = root/'Theme.qml.tmp'
    temporary.write_text(data)
    os.replace(temporary, selection)
    print('Tema ativo: ' + command)
