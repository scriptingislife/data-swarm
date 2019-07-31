import threading
import socket
import json
import boto3
import uuid

class SocketThread(threading.Thread):
    def __init__(self, host, port, body, table):
        threading.Thread.__init__(self)
        self.host = host
        self.port = port
        self.body = body
        self.table = table

    def run(self):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.connect((host, port))
                s.sendall(bytes(body))
                data = b' '
                resp = ''
                while len(data):
                    data = s.recv(1)
                    if data == b'\r':
                        break
                    resp += data.decode()
        except Exception as e:
            self.table.put_item(Item={"uuid": str(uuid.uuid4()), "error_msg": str(e)})
            return {'error_msg': str(e)}

        return {'status_code': status_code}

def handler(event, context):
    #message = json.loads(event['Records'][0]['Sns']['Message'])
    print(event)
    host = event['host']
    body = event['body'].encode('ascii')
    try:
        port = int(event['port'])
    except KeyError:
        port = 80

    resource = boto3.resource('dynamodb')
    table = resource.Table('2FA-Swarm')

    

    status_code = int(resp.split(' ')[1])

    table.put_item(Item={"uuid": str(uuid.uuid4()), "status_code": status_code})

    return {'status_code': status_code}
