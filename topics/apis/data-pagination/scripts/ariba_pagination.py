import os
import time
import argparse
from os import getenv
from enum import Enum
import requests
import json
import urllib.parse

# Loading environment variables
from dotenv import load_dotenv
load_dotenv()

REALM = getenv('REALM')
API_OAUTH_URL = getenv('API_OAUTH_URL')
API_KEY = getenv('API_KEY')
BASE64_AUTHSTRING = getenv('BASE64_AUTHSTRING')
API_URL = getenv('API_URL')

VERBOSE = False


class RunMode(Enum):
    count = 'count'
    paginate = 'paginate'

    def __str__(self):
        return self.value


def get_access_token():
    # Read the acces_token from the file saved by the ariba_authentication.py script
    credential_path = f'{REALM}-token.json'
    if os.path.exists(credential_path):
        with open(credential_path) as json_file:
            data = json.load(json_file)
            access_token = data['access_token']
    else:
        raise ValueError(f"Authentication file {credential_path} does not exist. "
                         "Make sure you run the ariba_authentication.py script before attempting "
                         "to run this script.")

    return access_token


def call_ar_sync_api(view_template, filters, path="", page_token=None):
    '''
    Communicates with the SAP Ariba Analytical Reporting API.

    :param str view_template: The view template to call.
    :param str filters: The filters used to filter the view template data.
    :param str path: Used when we can to retrieve count of the view template.
    :param str page_token: Specify a page token in the request header.
    :return: The response from the SAP Ariba Analytical Reporting API in JSON format
    :rtype: json
    '''
    
    global MODE, SAVE

    # We always retrieve the access_token as it might change while we are retrieving
    # data from our API
    headers = {
        'Authorization': f"Bearer {get_access_token()}",
        'apiKey': API_KEY
    }

    request_url = f"{API_URL}/views/{view_template}{path}?realm={REALM}&filters={urllib.parse.quote(filters)}"

    if page_token is not None:
        request_url += f"&pageToken={page_token}"

    output_file_name = ""
    
    if SAVE:
        page_token_identifier = f"_{page_token}" if page_token else ""
        output_file_name = f"{REALM}_{view_template}_{MODE}{page_token_identifier}.json"

    print(f"==========================")
    print(f"👉 Request URL: {request_url} -> Output file: {output_file_name}")
    print(f"==========================")

    response = requests.request("GET", request_url, headers=headers)

    result = json.loads(response.text)

    if SAVE:
        with open(output_file_name, 'w') as output_file:
            json.dump(result, output_file)

    return result


def analytical_reporting_sync_api_count(view_template, filters):
    '''
    Retrieve the total number of records available for the view template,
    with the filter criteria specified.

    :param str view_template: The view template to call.
    :param str filters: The filters used to filter the view template data.
    '''

    parsed_json = call_ar_sync_api(view_template, filters, path="/count")

    print(f"Maximum records per page: {parsed_json['MaxRecordsInEachPage']}")
    print(f"Total number of pages in result set: {parsed_json['TotalPages']}")
    print(
        f"Total number of records in result set: {parsed_json['TotalRecords']}")


def analytical_reporting_sync_api_paginate(view_template, filters):
    '''
    Retrieve the records available for the view template,
    with the filter criteria specified.

    :param str view_template: The view template to call.
    :param str filters: The filters used to filter the view template data.
    '''

    page_token = ""
    cycle = 0

    while page_token != "STOP":

        parsed_json = call_ar_sync_api(view_template, filters, page_token=page_token)

        print(f"Current iteration: {cycle}")
        print(
            f"Total number of records in response: {len(parsed_json['Records'])}")

        # If no PageToken is included in the response, we set the value of page_token to STOP
        # so the while loop does not continue
        page_token = parsed_json["PageToken"] if "PageToken" in parsed_json else "STOP"

        print(f"Next page: {page_token}")

        cycle += 1

    print("Finished!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='SAP Ariba API pagination')

    parser.add_argument('--mode', type=RunMode,
                        default=RunMode.paginate, choices=list(RunMode))
    parser.add_argument('--view_template', type=str, default='SourcingProjectSourcingSystemView',
                        help='Example value: SourcingProjectSourcingSystemView')
    parser.add_argument('--filters', type=str,
                        help='Example value: \'{"createdDateFrom":2019-07-07T00:00:00Z","createdDateTo":"2020-07-06T00:00:00Z"}\'')
    
    save_parser = parser.add_mutually_exclusive_group(required=False)
    save_parser.add_argument('--save', dest='save', action='store_true', help="Save the response payloads.")
    
    parser.set_defaults(save=False)

    args = parser.parse_args()

    MODE = args.mode
    SAVE = args.save
    
    if args.filters is None:
        raise ValueError('Need to specify a value for --filters parameter. ' +
                         'Example of value expected: \'{"createdDateFrom":"2019-07-07T00:00:00Z","createdDateTo":"2020-07-06T00:00:00Z"}\'')

    if args.mode == RunMode.count:
        analytical_reporting_sync_api_count(args.view_template, args.filters)
    elif args.mode == RunMode.paginate:
        analytical_reporting_sync_api_paginate(args.view_template, args.filters)
    else:
        raise ValueError(
            f"Value specified for --mode parameter is not valid. Possible values: {list(RunMode)}")
