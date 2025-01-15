import json
import boto3
from datetime import datetime
s3_client = boto3.client('s3')
BUCKET_NAME = 'vidhu-stock-data-bucket'

def lambda_handler(event, context):
    """
    Processes stock price data from SQS messages and stores in S3.
    """
    processed_count = 0
    failed_count = 0
    
    for record in event['Records']:
        try:
            # Parse the message body
            body = json.loads(record['body'])
            
            # Validate message
            required_fields = ['ticker', 'timestamp', 'price', 'currency']
            missing_fields = [field for field in required_fields if field not in body]
            
            if missing_fields:
                raise ValueError(f"Missing required fields in message: {', '.join(missing_fields)}")
            
            # Generate a unique filename using current timestamp
            current_time = datetime.now().strftime('%Y-%m-%d_%H-%M-%S-%f')
            
            # Create S3 key with proper directory structure and unique timestamp
            s3_key = f"stock_data/{body['ticker']}/{body['timestamp']}_{current_time}.json"
            
            # Store in S3
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=json.dumps(body),
                ContentType='application/json'
            )
            
            processed_count += 1
            print(f"Successfully processed data for {body['ticker']} at {body['timestamp']}")
            
        except Exception as e:
            failed_count += 1
            print(f"Error processing message: {str(e)}")
            # Re-raise the exception to trigger SQS retry
            raise e
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Processing complete',
            'processed_count': processed_count,
            'failed_count': failed_count
        })
    }