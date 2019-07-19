import boto3
import json

def handler(event, context):
    message = {
        'host': event['host'],
        'body': event['body']
    }

    arn = 'arn:aws:sns:us-east-1:358663747217:2fa-swarm'
    client = boto3.client('sns')
    response = client.publish(
        TargetArn=arn,
        Message=json.dumps(message),
        MessageStructure='json'
    )

    return {'response': str(response)}
