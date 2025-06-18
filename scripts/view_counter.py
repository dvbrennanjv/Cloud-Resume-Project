import boto3 # AWS SDK for Python
import json

# Sets up a connection to our DB
dynamodb = boto3.resource('dynamodb')
# Grabs a reference to our table itself (make sure to put your table name)
table = dynamodb.Table('view-counter')

# Define our headers
headers = {
     'Access-Control-Allow-Origin': 'HTTPS://OUR-WEBSITE.COM'
}

def lambda_handler(event, context):
    try:
        # We use update_item as its atomic allowing for concurrent viewers
        response = table.update_item(
            # Again make sure this key:value matches your table
            Key={'id': 'viewCount'},
            # SET views : This is telling DyanmoDB to set the value of 'views'
            # if_not_exists : handles our first time visitor incase the item doesnt exist
            UpdateExpression="SET #v = if_not_exists(#v, :start) + :inc",
            ExpressionAttributeNames={
                "#v": "views"
            },
            ExpressionAttributeValues={
                # incrementing by 1
                ':inc': 1,
                # default starting value
                ':start': 0
            },
            ReturnValues="UPDATED_NEW"
        )

        views = int(response['Attributes']['views'])
        # this is the response Lambda sends back to our API gateway letting us know everything was good
        return {
            'statusCode': 200,
            'headers' : headers,
            'body': json.dumps({'views': views})
        }
    
    except Exception as e:
        return{
            'statusCode': 500,
            'headers' : headers,
            'body': json.dumps({'error': str(e)})
        }