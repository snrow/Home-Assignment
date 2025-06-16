from flask import Flask, request, jsonify
import boto3
import os
from datetime import datetime
 
app = Flask(__name__)

# Initialize AWS clients
sqs = boto3.client('sqs', region_name='eu-central-1')

# Use token from environment variable (injected via secrets)
TOKEN = os.environ['TOKEN']
QUEUE_URL = os.environ['SQS_QUEUE_URL']

@app.route('/', methods=['GET', 'POST'])
def handle_request():
    if request.method == 'GET':
        return jsonify({'status': 'healthy'}), 200

    # Parse JSON payload for POST
    data = request.json
    if not data or 'token' not in data or 'data' not in data:
        return jsonify({'error': 'Invalid payload'}), 400

    # Validate token
    if data['token'] != TOKEN:
        return jsonify({'error': 'Invalid token'}), 401

    # Validate email_timestream
    payload_data = data['data']
    if 'email_timestream' not in payload_data:
        return jsonify({'error': 'Missing email_timestream'}), 400
    try:
        datetime.fromisoformat(payload_data['email_timestream'])
    except ValueError:
        return jsonify({'error': 'Invalid email_timestream format'}), 400

    # Send payload to SQS
    sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=str(payload_data))
    return jsonify({'message': 'Message sent to SQS'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
