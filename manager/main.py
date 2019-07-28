import boto3
import json
import os
import threading

def LaunchThread(threading.Thread):
    def __init__(self, sns, arn, message):
        threading.Thread.__init__(self)
        self.client = sns
        self.arn = arn
        self.message = message

    def run(self):
        self.client.publish(
            TargetArn=self.arn,
            Message=self.message,
            MessageStructure='json'
        )

def handler(event, context):
    payload = {
        'default': {
            'host': event['host'],
            'body': event['body']
        }
    }
    message = json.dumps(payload)


    #arn = 'arn:aws:sns:us-east-1:358663747217:2fa-swarm'
    arn = os.environ.get('SWARM_SNS_TOPIC_ARN')
    client = boto3.client('sns')

    if 'times' in event.keys():
        for _ in range(int(event['times'])):
            try:
                t = LaunchThread(client, arn, message)
                t.start()
            except Exception as e:
                print(e)
        response = 'success'
    else:
        response = client.publish(
            TargetArn=arn,
            Message=json.dumps(message),
            MessageStructure='json'
        )

    return {'response': str(response)}
