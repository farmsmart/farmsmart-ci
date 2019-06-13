#!/usr/bin/python
from google.oauth2 import service_account
import googleapiclient.discovery
import os
import json

PROJECT_ID = os.environ['project_id']
SERVICE_ACCOUNT_FILE = os.environ['service_account_file']
SCOPES = ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']

credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)

firebase = googleapiclient.discovery.build('firebase', 'v1beta1', credentials=credentials)

body = {
  'timeZone': 'Etc/GMT',
  'regionCode': 'GB',
  'locationId': 'europe-west2'
}

#response = firebase.projects().addFirebase(project=f'projects/{PROJECT_ID}', body=body).execute()
#print(response)