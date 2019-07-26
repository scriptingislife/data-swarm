import socket
import json
import boto3
import uuid

def handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])
    host = message['host']
    body = message['body'].encode('ascii')

    resource = boto3.resource('dynamodb')
    table = resource.Table('2FA-Swarm')

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((host, 80))
        s.sendall(bytes(body))
        data = s.recv(1024)

    decoded = data.decode()
    obj = json.loads(decoded[decoded.index('{'):decoded.index('}') + 1].strip())
    ip = obj['origin'][:obj['origin'].index(',')]

    table.put_item(Item={"uuid": str(uuid.uuid4()), "ip": ip})

    print(ip)
    return {'response': ip}
