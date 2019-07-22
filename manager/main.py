import boto3
import json
import os

def handler(event, context):
    message = {
        'host': event['host'],
        'body': event['body']
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
