import os
import datetime
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
import pyodbc

SQL_SERVER_CONFIG = {
    'server': 'serevr',
    'database': 'reporting',
    'username': 'sa',
    'password': 'pwd',
    'port':'4345'
}

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

def store_metrics_in_db(whenchecked,domain_name,metrics):
    """Store the fetched metrics into the SQL Server database."""
    try:
        connection_string = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={SQL_SERVER_CONFIG['server']},{SQL_SERVER_CONFIG['port']};"
            f"DATABASE={SQL_SERVER_CONFIG['database']};"
            f"UID={SQL_SERVER_CONFIG['username']};"
            f"PWD={SQL_SERVER_CONFIG['password']};"      
        )
        connection = pyodbc.connect(connection_string)
        cursor = connection.cursor()
        
        check_query = ("SELECT COUNT(*) FROM GooglePostmasterData WHERE domainname = ? AND whenchecked = ?")
        cursor.execute(check_query, (domain_name, whenchecked))
        record_exists = cursor.fetchone()[0]
        if record_exists == 0:
            add_stats = (
                "INSERT INTO GooglePostmasterData "
                "(domainname,whenchecked, spamrate, domainreputation, SpfSuccessRatio, "
                "DkimSuccessRatio, DmarcSuccessRatio, InboundEncryptionRatio, "
                "IpReputations, DeliveryErrors) "
                "VALUES (?,?, ?, ?, ?, ?, ?, ?, ?, ?)"
            )

            data_stats = (
                domain_name,
                whenchecked,
                metrics.get('userReportedSpamRatio', 0) * 100 if metrics.get('userReportedSpamRatio') is not None else 0.00,
                metrics.get('domainReputation', 'NA'),
                metrics.get('spfSuccessRatio', 0),
                metrics.get('dkimSuccessRatio', 0),
                metrics.get('dmarcSuccessRatio', 0),
                metrics.get('inboundEncryptionRatio', 0),
                str(metrics.get('ipReputations', 'N/A')),
                str(metrics.get('deliveryErrors', 'N/A'))
            )
            
            cursor.execute(add_stats, data_stats)
            connection.commit()
            print("Data stored in the database successfully.")
        else:
             print(f"Record for domain '{domain_name}' and date '{whenchecked}' already exists. Skipping insertion.")
        cursor.close()
        connection.close()
        print("Data stored in the database successfully.")
    except pyodbc.Error as err:
        print(f"Error: {err}")
    except Exception as e:
        print(f"Unexpected error: {e}")

def get_domain_metrics(service, domain_name, days):
    """Fetch and print spam rate and domain reputation for the last 'days' days."""
    today = datetime.date.today()
    for i in range(days):
        date_offset = 1  # Start by checking 1 days ago
        for attempt in range(3):  # Attempt to fetch metrics for 1, 2, and 3 days ago
            date = (today - datetime.timedelta(days=i+date_offset)).strftime('%Y%m%d')
            try:
                name = f'domains/{domain_name}/trafficStats/{date}'
                metrics = service.domains().trafficStats().get(name=name).execute()
                # Convert date_str back to a date object
                date_obj = datetime.datetime.strptime(date, '%Y%m%d').date()
                whenchecked = date_obj.strftime('%Y-%m-%d')
                try:
                    store_metrics_in_db(whenchecked, domain_name, metrics)
                    break  # Exit the loop if the request was successful
                except Exception as e:
                    print(f"Error storing metrics for {date}: {e}")
            except Exception as e:
                print(f"Error fetching metrics for {domain_name} on {date}: {e}")
                date_offset += 1  # Increase the offset to try the next earlier day


def list_domains(service, days):
    """List domains and fetch their metrics."""
    try:
        response = service.domains().list().execute()
        domains = response.get('domains', [])
        if not domains:
            print("No domains found.")
            return
        for domain in domains:
            domain_name = domain['name'].replace('domains/', '')
            print(f"Fetching metrics for domain: {domain_name}")
            try:
                get_domain_metrics(service, domain_name, days)
            except Exception as e:
                print(f"Error get_domain_metrics : {e}")    
    except Exception as e:
        print(f"Error listing domains: {e}")

def main():
    creds = authenticate_gmail_postmaster()
    service = build('gmailpostmastertools', 'v1', credentials=creds)
    list_domains(service, days=3)

if __name__ == '__main__':
    main()
