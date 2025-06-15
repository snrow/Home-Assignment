FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
ENV AWS_REGION=eu-central-1
ENV SQS_QUEUE_URL=https://sqs.eu-central-1.amazonaws.com/048999592382/sqs-eliran
ENV S3_BUCKET_NAME=data-bucket-eliran-prod
ENV POLL_INTERVAL=10
CMD ["python", "app.py"]