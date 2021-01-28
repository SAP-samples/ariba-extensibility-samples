import os
import time
import argparse
from os import getenv
from enum import Enum
import requests
import json
from datetime import datetime, timedelta

# Loading environment variables
from dotenv import load_dotenv
load_dotenv()

REALM = getenv('REALM')
API_OAUTH_URL = getenv('API_OAUTH_URL')
BASE64_AUTHSTRING = getenv('BASE64_AUTHSTRING')

NEXT_REFRESH = None
VERBOSE = False


class RunMode(Enum):
    access_token = 'access_token' 
    refresh_token = 'refresh_token'
    loop = 'loop'
    
    def __str__(self):
        return self.value


def get_access_token():
    global NEXT_REFRESH
    NEXT_REFRESH = datetime.now() + timedelta(seconds=1320)

    payload = 'grant_type=client_credentials'
    headers = {
        'Authorization': f"Basic {BASE64_AUTHSTRING}",
        'Content-Type': 'application/x-www-form-urlencoded'
    }

    response = requests.request("POST", API_OAUTH_URL, headers=headers, data=payload)
    parsed_json = json.loads(response.text)

    # Store credentials in a file, to be used by the refresh_token mechanism
    with open(f'{REALM}-token.json', 'w') as outfile:
        json.dump(parsed_json, outfile)

    if VERBOSE:
        print(f"Authentication response: \n{json.dumps(parsed_json, indent = 1)}")
    
    print(f"Next refresh: {NEXT_REFRESH}")
    

def refresh_access_token():
    global NEXT_REFRESH

    refresh_token = None

    # Read the refresh_token from the previously acquired access_token
    credential_path = f'{REALM}-token.json'
    if os.path.exists(credential_path):
        with open(credential_path) as json_file:
            data = json.load(json_file)
            refresh_token = data['refresh_token']

    if refresh_token is not None:
        payload = f'grant_type=refresh_token&refresh_token={refresh_token}'
        headers = {
            'Authorization': f"Basic {BASE64_AUTHSTRING}",
            'Content-Type': 'application/x-www-form-urlencoded'
        }

        response = requests.request("POST", API_OAUTH_URL, headers=headers, data=payload)
        parsed_json = json.loads(response.text)
        
        expires_in = parsed_json['expires_in']

        # Store refresh token in file
        with open(credential_path, 'w') as outfile:
            json.dump(parsed_json, outfile)

        # Calculate when the next refresh will occur
        NEXT_REFRESH = datetime.now() + timedelta(seconds=expires_in - 120)

        if VERBOSE:
            print(f"Refresh token response: \n{json.dumps(parsed_json, indent = 1)}")
        
        print(f"Next refresh: {NEXT_REFRESH}")
    else:
        get_access_token()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='SAP Ariba authentication')

    parser.add_argument('--mode', type=RunMode, default=RunMode.loop, choices=list(RunMode))

    verbose_parser = parser.add_mutually_exclusive_group(required=False)
    verbose_parser.add_argument('--verbose', dest='verbose', action='store_true', help="Print out authentication response.")
    
    parser.set_defaults(verbose=False)
    
    args = parser.parse_args()

    VERBOSE = args.verbose
    MODE = args.mode

    if args.mode == RunMode.access_token:
        get_access_token()
    elif args.mode == RunMode.refresh_token:
        refresh_access_token()
    elif args.mode == RunMode.loop:
        while True == True:
            if(NEXT_REFRESH is None):
                refresh_access_token()
            elif datetime.now() >= NEXT_REFRESH:
                refresh_access_token()
            time.sleep(int(getenv('TOKEN_DELAY')))
    else:
        raise ValueError(f"Value specified for --mode parameter is not valid. Possible values: {list(RunMode)}")
