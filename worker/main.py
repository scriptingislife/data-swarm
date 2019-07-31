import socket
import json
import uuid

def handler(event, context):
    print(event)
    host = event['host']
    body = event['body'].encode('ascii')
    try:
        port = int(event['port'])
    except KeyError:
        port = 80

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((host, port))
            s.sendall(bytes(body))
            #data = b' '
            #resp = ''
            #while len(data):
            #    data = s.recv(1)
            #    if data == b'\r':
            #        break
            #    resp += data.decode()
    except Exception as e:
        return {'success': False, 'error_msg': str(e)}

    return {'success': True}
