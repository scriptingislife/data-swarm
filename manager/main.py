import boto3
import json
import os

def handler(event, context):
    payload = {
        'host': event['host'],
        'body': event['body']
    }
    message = {
        'default': json.dumps(payload)
    }

    #arn = 'arn:aws:sns:us-east-1:358663747217:2fa-swarm'
    arn = os.environ.get('SWARM_SNS_TOPIC_ARN')
    client = boto3.client('sns')
    response = client.publish(
        TargetArn=arn,
        Message=json.dumps(message),
        MessageStructure='json'
    )

    return {'response': str(response)}
