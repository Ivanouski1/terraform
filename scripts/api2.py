import json
from datetime import datetime
def lambda_handler(event, context):
    current_time = datetime.now().strftime("%m-%d-%Y %H:%M:%S") 
    message = "Hello from Lambda number two! The date is {}".format(current_time)
    return {
        'statusCode': 200,
        'body': json.dumps(message)
    }
