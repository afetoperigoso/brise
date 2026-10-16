#!/usr/bin/env python3
"""Uma solicitação BlueZ por ação, sem repetição automática."""
import json
import sys
import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

def emit(**data):
    print(json.dumps(data, ensure_ascii=False), flush=True)

DBusGMainLoop(set_as_default=True)
try:
    bus = dbus.SystemBus()
    obj = bus.get_object('org.bluez', sys.argv[2])
    if sys.argv[1] == 'power':
        dbus.Interface(obj, 'org.freedesktop.DBus.Properties').Set('org.bluez.Adapter1', 'Powered', dbus.Boolean(sys.argv[3] == 'on'), timeout=15)
        emit(kind='done')
    else:
        adapter = dbus.Interface(obj, 'org.bluez.Adapter1')
        adapter.StartDiscovery(timeout=15)
        emit(kind='scanning')
        loop = GLib.MainLoop()
        def finish():
            try: adapter.StopDiscovery(timeout=10)
            except dbus.DBusException: pass
            loop.quit()
            return False
        GLib.timeout_add_seconds(20, finish)
        loop.run()
except dbus.DBusException as exc:
    name = exc.get_dbus_name()
    messages = {
        'org.bluez.Error.InProgress': 'Já existe uma busca em andamento. Aguarde antes de tentar novamente.',
        'org.bluez.Error.Busy': 'Adaptador ocupado. Aguarde antes de tentar novamente.',
        'org.bluez.Error.NotReady': 'Ligue o Bluetooth antes de buscar dispositivos.',
        'org.bluez.Error.NotAuthorized': 'Sem autorização para alterar o Bluetooth.',
    }
    emit(kind='error', message=messages.get(name, 'Bluetooth: ' + str(exc)))
    sys.exit(1)
