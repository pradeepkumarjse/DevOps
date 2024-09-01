import os
import datetime
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# Define the scopes required for the API
SCOPES = ['https://www.googleapis.com/auth/postmaster.readonly']
CLIENT_SECRETS_FILE = 'client_secrets.json'
TOKEN_FILE = 'token.json'

def authenticate_gmail_postmaster():
    """Authenticate the user and return the Google API credentials."""
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRETS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
    return creds

def get_domain_metrics(service, domain_name, days=2):
    """Fetch and print spam rate and domain reputation for the last 'days' days."""
    today = datetime.date.today()
    for i in range(days):
        date = (today - datetime.timedelta(days=i+3)).strftime('%Y%m%d')  # Correct date format to YYYYMMDD
        try:
            name = f'domains/{domain_name}/trafficStats/{date}'
            metrics = service.domains().trafficStats().get(name=name).execute()

            print(metrics)
            
            spam_rate = metrics.get('spamRate', 'N/A')
            domain_reputation = metrics.get('domainReputation', 'N/A')

            print(f"Date: {date}, Domain: {domain_name}")
            print(f"Spam Rate: {spam_rate}, Domain Reputation: {domain_reputation}")
            print("-" * 40)
        except Exception as e:
            print(f"Error fetching metrics for {domain_name} on {date}: {e}")
            print("-" * 40)

def list_domains(service, days=2):
    """List domains and fetch their metrics."""
    try:
        response = service.domains().list().execute()
        domains = response.get('domains', [])
        if not domains:
            print("No domains found.")
            return
        for domain in domains:
            domain_name = domain['name'].replace('domains/', '')  # Remove 'domains/' prefix if present
            print(f"Fetching metrics for domain: {domain_name}")
            get_domain_metrics(service, domain_name, days)
    except Exception as e:
        print(f"Error listing domains: {e}")

def main():
    creds = authenticate_gmail_postmaster()
    service = build('gmailpostmastertools', 'v1', credentials=creds)
    list_domains(service, days=2)

if __name__ == '__main__':
    main()
