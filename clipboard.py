#!/usr/bin/env python3
"""Histórico local de clipboard Wayland, texto e imagens; até 80 itens."""
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import time

root = Path(os.environ.get('XDG_STATE_HOME', str(Path.home()/'.local/state'))) / 'brise/clipboard'
root.mkdir(mode=0o700, parents=True, exist_ok=True)
os.chmod(root, 0o700)
dbpath = root/'history.sqlite3'
db = sqlite3.connect(dbpath)
os.chmod(dbpath, 0o600)
db.execute('CREATE TABLE IF NOT EXISTS clips (id TEXT PRIMARY KEY, mime TEXT, body BLOB, title TEXT, updated REAL)')
command = sys.argv[1]
if command == 'capture':
    if os.environ.get('CLIPBOARD_STATE') in ('nil', 'clear', 'sensitive'): sys.exit(0)
    incoming = sys.stdin.buffer.read(10 * 1024 * 1024 + 1)
    if len(incoming) > 10 * 1024 * 1024: sys.exit(0)
    types = subprocess.run(['wl-paste', '--list-types'], capture_output=True, timeout=3)
    available = types.stdout.decode(errors='replace').splitlines()
    mime = next((m for m in ('image/png', 'image/jpeg', 'image/webp', 'text/plain;charset=utf-8', 'text/plain') if m in available), None)
    if mime is None: sys.exit(0)
    # --watch entrega os bytes ao stdin, preservando o tipo anunciado.
    # Leia explicitamente o tipo escolhido para formatos múltiplos.
    proc = subprocess.run(['wl-paste', '--no-newline', '--type', mime], capture_output=True, timeout=5)
    body = proc.stdout
    if proc.returncode or not body or len(body) > 10 * 1024 * 1024: sys.exit(0)
    digest = hashlib.sha256(mime.encode()+body).hexdigest()
    title = body.decode('utf-8', errors='replace') if mime.startswith('text/') else 'Imagem'
    if mime.startswith('image/'):
        (root/(digest+'.'+mime.split('/')[1])).write_bytes(body)
    with db:
        db.execute('INSERT OR REPLACE INTO clips VALUES (?, ?, ?, ?, ?)', (digest, mime, body, title[:20000], time.time()))
        stale = db.execute('SELECT id,mime FROM clips ORDER BY updated DESC LIMIT -1 OFFSET 80').fetchall()
        for clipid, oldmime in stale:
            db.execute('DELETE FROM clips WHERE id=?', (clipid,))
            if oldmime.startswith('image/'): (root/(clipid+'.'+oldmime.split('/')[1])).unlink(missing_ok=True)
elif command == 'list':
    rows = db.execute('SELECT id,mime,title FROM clips ORDER BY updated DESC').fetchall()
    print(json.dumps([{'id': i, 'mime': m, 'title': t, 'image': str(root/(i+'.'+m.split('/')[1])) if m.startswith('image/') else ''} for i,m,t in rows], ensure_ascii=False))
elif command == 'copy':
    row = db.execute('SELECT mime,body FROM clips WHERE id=?', (sys.argv[2],)).fetchone()
    if row is None: sys.exit(1)
    subprocess.run(['wl-copy', '--type', row[0]], input=row[1], check=True, timeout=5)
