FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
ENV AWS_REGION=eu-central-1
ENV TOKEN_PARAM_NAME=/app/frontend/token
ENV SQS_QUEUE_URL=https://sqs.eu-central-1.amazonaws.com/048999592382/sqs-eliran
EXPOSE 5000
CMD ["python", "app.py"]