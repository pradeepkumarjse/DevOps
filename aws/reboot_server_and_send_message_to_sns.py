import json
import urllib3
import boto3

import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText



EMAIL_SENDER = "9@gmail.com"
EMAIL_RECIPIENT = "@gmail.com"
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_USERNAME = "9560.com"
SMTP_PASSWORD = ""


source_access_key = ''
source_secret_key = ''
   
# Origin source region where db instance is running
source_region_name='us-east-1'

# Initialize clients
ec2_client = boto3.client('ec2',region_name=source_region_name, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)
sns_client = boto3.client('sns',region_name=source_region_name, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)
http = urllib3.PoolManager()
ssm_client = boto3.client('ssm',region_name=source_region_name, aws_access_key_id=source_access_key, aws_secret_access_key=source_secret_key)


# Configuration
URL = "https://dummy.restapiexample.com/api/v1/employees"  # URL to check
INSTANCE_ID = "i-0e22d053df5df7cd4"  # EC2 Instance ID
SNS_TOPIC_ARN = "arn:aws:sns:us-east-1:254438258404:notifyc"  # SNS Topic ARN
REGION = "us-east-1"  # AWS Region

def lambda_handler(event, context):
    # Make an HTTP GET request to the URL
    response = http.request('GET', URL)
    print(response.status)
    if response.status != 200:
        # Reboot the EC2 instance if the response status is not 200 OK
        #reboot_instance(INSTANCE_ID)
        
        # Send notification to SNS topic
        #send_sns_notification(response.status)
        #send_email(400)
        run_command_on_instance(INSTANCE_ID, COMMAND)
    
    return {
        'statusCode': 200,
        'body': json.dumps('Lambda function executed successfully!')
    }

def reboot_instance(instance_id):
    try:
        # Reboot the instance
        ec2_client.reboot_instances(InstanceIds=[instance_id])
        print(f'Rebooting instance: {instance_id}')
        
    except Exception as e:
        print(f'Error rebooting instance: {str(e)}')

def send_sns_notification(response_status):
    try:
        subject = "EC2 Instance Reboot Notification"
        message = (f"The EC2 instance {INSTANCE_ID} was rebooted because the URL {URL} returned a {response_status} status code.")
        
        # Publish message to SNS topic
        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        
        print(f'SNS notification sent! Message ID: {response["MessageId"]}')
        
    except Exception as e:
        print(f'Error sending SNS notification: {str(e)}')


def send_email(response_status):
    try:
        subject = "EC2 Instance Reboot Notification"
        body_text = f"The EC2 instance {INSTANCE_ID} was rebooted because the URL {URL} returned a {response_status} status code."
        body_html = f"""<html>
        <head></head>
        <body>
          <h1>EC2 Instance Reboot Notification</h1>
          <p>The EC2 instance {INSTANCE_ID} was rebooted because the URL <a href='{URL}'>{URL}</a> returned a {response_status} status code.</p>
        </body>
        </html>
        """
        
        # Create the email message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = EMAIL_SENDER
        msg['To'] = EMAIL_RECIPIENT
        
        # Attach the email body to the message
        part1 = MIMEText(body_text, 'plain')
        part2 = MIMEText(body_html, 'html')
        msg.attach(part1)
        msg.attach(part2)
        
        # Connect to the SMTP server and send the email
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SMTP_USERNAME, SMTP_PASSWORD)
        server.sendmail(EMAIL_SENDER, EMAIL_RECIPIENT, msg.as_string())
        server.quit()
        
        print('Email sent!')
        
    except Exception as e:
        print(f'Error sending email: {str(e)}')
