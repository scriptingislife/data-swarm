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

    arn = os.environ.get('SWARM_SNS_TOPIC_ARN')
    #client = boto3.client('sns')
    client = boto3.client('lambda')

    if 'times' in event.keys():
        for _ in range(int(event['times'])):
            client.invoke(FunctionName='2fa_swarm_worker', InvocationType='Event', Payload=json.dumps(payload))
            #     client.publish(
            # TargetArn=arn,
            # Message=json.dumps(message),
            # MessageStructure='json'
            # )
        response = 'success'
    else:
        response = client.publish(
            TargetArn=arn,
            Message=json.dumps(message),
            MessageStructure='json'
        )

    return {'response': str(response)}
