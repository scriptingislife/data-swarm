import socket
import json

def handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])
    host = message['host']
    body = message['body'].encode('ascii')

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((host, 80))
        s.sendall(bytes(body))
        data = s.recv(1024)

    print(str(data))
    return {'response': str(data)}
