import boto3
import json
import os

def handler(event, context):
    payload = {
        'host': event['host'],
        'body': event['body']
    }

    if 'port' in event.keys():
        payload['port'] = event['port']

    message = {
        'default': json.dumps(payload)
    }

    functionName = os.environ.get('WORKER_FUNCTION_NAME')
    client = boto3.client('lambda')

    if 'times' in event.keys():
        for _ in range(int(event['times'])):
            client.invoke(FunctionName=functionName, InvocationType='Event', Payload=json.dumps(payload))
        response = 'success'
    else:
        response = client.invoke(FunctionName=functionName, InvocationType='Event', Payload=json.dumps(payload))

    return {'response': str(response)}
