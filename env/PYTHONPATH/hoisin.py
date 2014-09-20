import os
import socket
import json

class jsont(object):
    def __init__(self, sock):
        self.rfile = sock.makefile('r')
        self.wfile = sock.makefile('w')

    def send(self, msg):
        self.wfile.write(json.dumps(msg))
        self.wfile.write('\n')
        self.wfile.flush()

    def recv(self):
        return json.loads(self.rfile.readline())

class out_dict(dict):

    name = "dictionary"

    def __init__(self, cli, *args):
        dict.__init__(self, *args)
        self.cli = cli

    def __setitem__(self, k, v):
        dict.__setitem__(self, k, v)
        self.cli.ctl.send({ "output": {
            "set": { k: v }
        }})

    def __delitem__(self, k):
        dict.__delitem__(self, k)
        self.cli.ctl.send({ "output": {
            "delete": [k]
        }})


class ui(object):
    def __init__(self, cli, options):
        self.cli = cli
        self.options = options

class cli(object):
    def __init__(self):
        if 'HOISINCHANNEL' in os.environ:
            fd = int(os.environ['HOISINCHANNEL'])
            self.ctl = jsont(socket.fromfd(fd, socket.AF_UNIX, socket.SOCK_STREAM))
            self.connected = True
        else:
            self.connected = False

    def checkin(self, output_type):
        self.ctl.send({ "checkin": {
            "output_type": output_type.name
        }})
        return output_type(self)
