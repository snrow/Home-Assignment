import boto3
import os
import time
import json
import uuid
import logging
                
# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Initialize AWS clients
sqs = boto3.client('sqs', region_name=os.environ['AWS_REGION'])
s3 = boto3.client('s3', region_name=os.environ['AWS_REGION'])

# Configuration
QUEUE_URL = os.environ['SQS_QUEUE_URL']
BUCKET_NAME = os.environ['S3_BUCKET_NAME']
POLL_INTERVAL = int(os.environ.get('POLL_INTERVAL', 10))

def process_messages():
    logger.info("Starting queue-worker-service, polling SQS queue: %s", QUEUE_URL)
    while True:
        try:
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=10
            )
            logger.debug("Received response: %s", response)
            if 'Messages' in response:
                for message in response['Messages']:
                    body = message['Body']
                    receipt_handle = message['ReceiptHandle']
                    
                    # Generate a file name with DD-MM-YYYY-HH:MM and short UUID
                    timestamp = time.strftime("%d-%m-%Y-%H:%M")
                    file_name = f"{timestamp}-{str(uuid.uuid4())[:8]}.txt"
                    
                    # Upload to S3 with simpler prefix
                    s3_key = f"processed/{file_name}"
                    s3.put_object(
                        Bucket=BUCKET_NAME,
                        Key=s3_key,
                        Body=body
                    )
                    
                    # Delete message from SQS
                    sqs.delete_message(
                        QueueUrl=QUEUE_URL,
                        ReceiptHandle=receipt_handle
                    )
                    logger.info("Processed message: %s, uploaded to s3://%s/%s", body, BUCKET_NAME, s3_key)
            else:
                logger.debug("No messages received")
        except Exception as e:
            logger.error("Error processing message: %s", str(e))
        
        time.sleep(POLL_INTERVAL)

if __name__ == '__main__':
    process_messages()
