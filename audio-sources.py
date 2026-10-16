#!/usr/bin/env python3
"""Enumera todas as fontes expostas pelo servidor PulseAudio/PipeWire."""
import json
import subprocess
import sys
try:
    result = subprocess.run(['pactl', '--format=json', 'list', 'sources'], capture_output=True, text=True, check=True, timeout=3)
    default = subprocess.run(['pactl', 'get-default-source'], capture_output=True, text=True, check=True, timeout=3).stdout.strip()
    sources = []
    for source in json.loads(result.stdout):
        levels = [channel['value'] / 65536 for channel in source.get('volume', {}).values()]
        sources.append({'name': source['name'], 'description': source.get('description') or source['name'],
                        'id': source['index'], 'pulseSource': True, 'ready': True,
                        'audio': {'volume': sum(levels) / len(levels) if levels else 0, 'muted': bool(source.get('mute'))}})
    print(json.dumps({'sources': sources, 'default': default}, ensure_ascii=False))
except (subprocess.SubprocessError, OSError, ValueError, KeyError) as error:
    print(str(error), file=sys.stderr)
    sys.exit(1)
