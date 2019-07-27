import socket
import json
import boto3
import uuid

def handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])
    host = message['host']
    body = message['body'].encode('ascii')
    try:
        port = int(message['port'])
    except KeyError:
        port = 80

    resource = boto3.resource('dynamodb')
    table = resource.Table('2FA-Swarm')

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
        table.put_item(Item={"uuid": str(uuid.uuid4()), "error_msg": str(e)})
        return {'error_msg': str(e)}

    status_code = int(resp.split(' ')[1])

    table.put_item(Item={"uuid": str(uuid.uuid4()), "status_code": status_code})

    return {'status_code': status_code}
