class jsont(object):
    def __init__(self, sock):
        self.rfile = sock.makefile('r')
        self.wfile = sock.makefile('w')

    def send(self, msg):
        import json

        self.wfile.write(json.dumps(msg))
        self.wfile.write('\n')
        self.wfile.flush()

    def recv(self):
        import json

        return json.loads(self.rfile.readline())

class out_dict(dict):

    name = "dictionary"

    def __init__(self, *args):
        dict.__init__(self, *args)

    def __setitem__(self, k, v):
        dict.__setitem__(self, k, v)
        ctl.send({ "output": {
            "set": { k: v }
        }})

    def __delitem__(self, k):
        dict.__delitem__(self, k)
        ctl.send({ "output": {
            "delete": [k]
        }})


class ui(object):
    def __init__(self, options):
        self.options = options

def checkin(output_type):
    ctl.send({ "checkin": {
        "output_type": output_type.name
    }})
    return output_type()

class Hoisin(object):
    def __init__(self, ctl):
        self.ctl = ctl

    def __getattr__(self, name):
        def call(*args):
            self.ctl.send((name,) + args)
            return self.ctl.recv()
        return call

import os
import sys
import socket

if 'HOISINCHANNEL' in os.environ:
    fd = int(os.environ['HOISINCHANNEL'])
    ctl = jsont(socket.fromfd(fd, socket.AF_UNIX, socket.SOCK_STREAM))
    sys.modules[__name__] = Hoisin(ctl)
else:
    sys.modules[__name__] = None
