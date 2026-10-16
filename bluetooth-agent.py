#!/usr/bin/env python3
"""Agente BlueZ: encaminha confirmação/PIN para a interface via JSON."""
import json
import sys
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

DBusGMainLoop(set_as_default=True)
class Rejected(dbus.DBusException):
    _dbus_error_name = 'org.bluez.Error.Rejected'

def emit(**data):
    print(json.dumps(data, ensure_ascii=False), flush=True)

class Agent(dbus.service.Object):
    pending = None
    def prompt(self, kind, device, value, reply, error):
        if self.pending:
            error(Rejected('Outra solicitação em andamento'))
            return
        self.pending = (kind, reply, error)
        emit(kind=kind, device=str(device), value=str(value))

    @dbus.service.method('org.bluez.Agent1', in_signature='o', out_signature='s', async_callbacks=('reply', 'error'))
    def RequestPinCode(self, device, reply, error):
        self.prompt('pin', device, '', reply, error)

    @dbus.service.method('org.bluez.Agent1', in_signature='o', out_signature='u', async_callbacks=('reply', 'error'))
    def RequestPasskey(self, device, reply, error):
        self.prompt('passkey', device, '', reply, error)

    @dbus.service.method('org.bluez.Agent1', in_signature='ou', out_signature='', async_callbacks=('reply', 'error'))
    def RequestConfirmation(self, device, passkey, reply, error):
        self.prompt('confirm', device, f'{int(passkey):06d}', reply, error)

    @dbus.service.method('org.bluez.Agent1', in_signature='o', out_signature='', async_callbacks=('reply', 'error'))
    def RequestAuthorization(self, device, reply, error):
        self.prompt('confirm', device, '', reply, error)

    @dbus.service.method('org.bluez.Agent1', in_signature='os', out_signature='', async_callbacks=('reply', 'error'))
    def AuthorizeService(self, device, uuid, reply, error):
        self.prompt('confirm', device, '', reply, error)

    @dbus.service.method('org.bluez.Agent1', in_signature='ouq', out_signature='')
    def DisplayPasskey(self, device, passkey, entered):
        emit(kind='display', device=str(device), value=f'{int(passkey):06d}')

    @dbus.service.method('org.bluez.Agent1', in_signature='os', out_signature='')
    def DisplayPinCode(self, device, pin):
        emit(kind='display', device=str(device), value=str(pin))

    @dbus.service.method('org.bluez.Agent1', in_signature='', out_signature='')
    def Cancel(self):
        self.reject()
        emit(kind='clear')

    @dbus.service.method('org.bluez.Agent1', in_signature='', out_signature='')
    def Release(self):
        self.reject()
        loop.quit()

    def reject(self):
        if self.pending:
            _, _, error = self.pending
            self.pending = None
            error(Rejected('Cancelado'))

    def answer(self, data):
        if not self.pending: return
        kind, reply, error = self.pending
        self.pending = None
        if not data.get('accept'):
            error(Rejected('Recusado'))
        else:
            value = str(data.get('value', ''))
            if kind == 'pin' and 1 <= len(value) <= 16: reply(value)
            elif kind == 'passkey' and value.isdecimal() and len(value) <= 6: reply(dbus.UInt32(int(value)))
            elif kind == 'confirm': reply()
            else: error(Rejected('PIN inválido'))
        emit(kind='clear')

loop = GLib.MainLoop()
try:
    bus = dbus.SystemBus()
    agent = Agent(bus, '/brise/agent')
    manager = dbus.Interface(bus.get_object('org.bluez', '/org/bluez'), 'org.bluez.AgentManager1')
    manager.RegisterAgent('/brise/agent', 'KeyboardDisplay')
    # Chamadas Pair() originadas por outra conexão precisam do agente padrão.
    manager.RequestDefaultAgent('/brise/agent')
    emit(kind='ready')
    def receive(source, condition):
        line = sys.stdin.readline()
        if not line:
            agent.reject()
            loop.quit()
            return False
        try: agent.answer(json.loads(line))
        except (ValueError, TypeError): pass
        return True
    GLib.io_add_watch(sys.stdin, GLib.IO_IN | GLib.IO_HUP, receive)
    loop.run()
except dbus.DBusException as exc:
    emit(kind='error', value=str(exc))
    sys.exit(1)
