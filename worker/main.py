import socket

def handler(event, context):
    host = event['host']
    body = event['body'].encode('ascii')

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((host, 80))
        s.sendall(bytes(body))
        data = s.recv(1024)

    return {'response': str(data)}
