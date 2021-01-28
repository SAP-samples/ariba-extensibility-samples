# Authentication & refresh tokens with SAP Ariba APIs

> This content was originally created as an exercise for the [Devtoberfest Cloud APIs event](https://github.com/SAP-samples/cloud-apis-virtual-event/) - [Exercise 07](https://github.com/SAP-samples/cloud-apis-virtual-event/tree/main/exercises/07).

If you are not familiar with the basic concepts of OAuth 2.0, checkout Exercises 1 and 2 of the [Devtoberfest Cloud APIs event](https://github.com/SAP-samples/cloud-apis-virtual-event/). Here, we'll look at how to authenticate and use refresh tokens with the SAP Ariba APIs using Python. We will first retrieve an access token, look at the response of the authentication server and refresh an access token once the original token expires.

The SAP Ariba APIs allows creating integrations between applications/services/machines. The APIs are commonly used to extend the capabilities of SAP Ariba, e.g. extend approval process, interact with invoices, or it can just be to retrieve transactional/analytical data from the SAP Ariba realm (instance).

To allow programmatic access to an SAP Ariba realm, an application will need to be created in the [SAP Ariba developer portal](https://developer.ariba.com) and go through the application approval process. Once the approval process completes, the developer portal administrator will be able to generate OAuth credentials for the application. These OAuth credentails are required to complete this exercise.

> For this exercise, the OAuth credentials of any SAP Ariba API will work, as we will focus purely on authentication and we will not retrieve data from SAP Ariba.

## Steps

After completing the steps in this exercise you'll know how to authenticate agains the SAP Ariba APIs and have an understanding of an OAuth 2.0 response, what the different fields returned mean and how to use the `refresh_token` and why it is needed.

:point_right: To run the Python scripts included in this exercise, ensure that you checkout the [exercise-specific prerequisites](prerequisites.md).

### 1. Get familiar with an OAuth 2.0 successful response

As mentioned in a previous [exercise](../02/readme.md), OAuth 2.0 is an industry standard, based on work within the context of the Internet Engineering Task Force (IETF) and codified in [RFC 6749 - The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749). Before authenticating against the SAP Ariba APIs, lets remind ourselves what we should expect as a successful authentication response. For this, we can reference to [RFC 8693 - OAuth 2.0 Token Exchange](https://tools.ietf.org/html/rfc8693), which contains additional details and explanation on the different fields that we can expect in the response of an authentication request.

:point_right: Visit the [RFC 8693 - 2.2.1 Successful Response section](https://tools.ietf.org/html/rfc8693#section-2.2.1) and get familiar with the fields we should expect in the response from the SAP Ariba authorization server.

> Pay special attention to the explanations of the `access_token`, `refresh_token`, `token_type` and `expires_in` fields.

Below an example of a response from a successful OAuth 2.0 request:
```json
{
    "access_token": "dc1aaf96-5987-4bcc-aeba-426e80f7e168",
    "refresh_token": "c6ef16aa-26d6-4296-9507-eded862d7e1b",
    "token_type": "bearer",
    "scope": null,
    "expires_in": 1440
}
```

Lets quickly see what each of the fields above are:
- `access_token`: This is the security token issued by the OAuth server. We will need to send this value in the `Authorization` header when retrieving data from the API. Example of `Authorization` header value -> `Bearer dc1aaf96-5987-4bcc-aeba-426e80f7e168`
- `refresh_token`: Given that the SAP Ariba API access token expires, the OAuth server returns a `refresh_token`. This `refresh_token` will be used to get a new `access_token` when the original `access_token` retrieved expires.

  *From RFC 8693 -> A refresh token can be issued in cases where the client of the token exchange needs the ability to access a resource even when the original credential is no longer valid (e.g., user-not-present or offline scenarios where there is no longer any user entertaining an active session with the client).*
- `token_type`: Indicate the type of the `access_token` issued. As shown in an example above, `Bearer` is specified in the `Authorization` header.

    *From RFC 8693 -> The client can simply present it (the access token) as is without any additional proof of eligibility beyond the contents of the token itself.*
- `expires_in`: This field tells us how long before our `access_token` expires. If we are continuously calling the API, we will need to make sure that the `access_token` is refreshed before it expires.


### 2. Set up the SAP Ariba API details in script

Enough of explanations, lets jump to some code. Before sending an authentication request we will specify the application details previously shared by an SAP Ariba developer portal administrator in our environment configuration.

The Python script uses [python-dotenv](https://pypi.org/project/python-dotenv/) to set some environment variable required by the script.

:point_right: Navigate to the scripts folder and create a file called `.env`. Copy and paste the sample config settings shown below and replace the values of `REALM`, `API_OAUTH_URL`, `API_KEY`, and `BASE64_AUTHSTRING` with the values provided by your administrator.

> For a detailed explanation of the SAP Ariba developer portal, creating an application and its approval process, checkout the [SAP Ariba for Developers YouTube playlist :tv:](https://www.youtube.com/watch?v=oXW3SBCadoI&list=PL6RpkC85SLQDXSLHrSPtu8wztzDs8kYPX)

The contents of the new `.env` file should look similar to the one below:
```text
############
# Config settings
############

# Value in seconds
TOKEN_DELAY=5

############
# Ariba API
############

REALM=MyRealm-T
API_OAUTH_URL="https://api.ariba.com/v2/oauth/token"
API_KEY=YXBwbGljYXRpb25faWRfYWthX2FwaV9rZXkK
BASE64_AUTHSTRING=b2F1dGhfY2xpZW50X2lkOm9hdXRoX2NsaWVudF9zZWNyZXRfbm90X3RoYXRfc2VjcmV0Cg==
```

Now that you've set the API details, we can send an authentication request to the SAP Ariba API OAuth server.

### 3. Explore the [`ariba_authentication.py`](scripts/ariba_authentication.py) script

:point_right: Go to the scripts folder, open the [`ariba_authentication.py`](scripts/ariba_authentication.py) file and go through the code.

The [`ariba_authentication.py`](scripts/ariba_authentication.py) script, included in this exercise, was created to facilitate completing the exercise. It will use credentials set up in the step above to authenticate against the OAuth server. You can use it to get a new access token and refresh an existing token.

The script can be run in the following modes (by specifying the `--mode` parameter):
- `access_token`: Gets a new access token from the OAuth server.
- `refresh_token`: Uses the previously retrieved access token to get a new access token from the OAuth server.
- `loop`: Runs continuously and it will refresh an access token before it expires.

> For the sake of simplicity, the script will be storing the response from the OAuth server in a local file. This file is used by the script when running in refresh_token mode. Also, you can check the OAuth server response and get familiar with the structure.

### 4. Authenticate against the SAP Ariba API (Get an `access_token`)

The code sample below shows what it is required, from a request perspective, to authenticate against the SAP Ariba API OAuth server. You will need to specify `client_credentials` as the `grant_type` and include the `BASE64_AUTHSTRING` value in the `Authorization` header.

```python
# Code from ariba_authentication.py script L37-43
payload = 'grant_type=client_credentials'
headers = {
    'Authorization': f"Basic {BASE64_AUTHSTRING}",
    'Content-Type': 'application/x-www-form-urlencoded'
}

response = requests.request("POST", API_OAUTH_URL, headers=headers, data=payload)
```

:point_right: As it will be the first time you authenticate against the SAP Ariba APIs, you will need to acquire an access token. To facilitate this, run the following from command line:
```bash
$ python ariba_authentication.py --mode=access_token --verbose
```

The output of the command above will be similar to the following response:
```json
Authentication response:
{
 "access_token": "c90bcfc4-0222-4501-93d4-1d77abb4aa13",
 "refresh_token": "2ef288b1-4007-4b57-bc68-69b0378c7880",
 "token_type": "bearer",
 "scope": null,
 "expires_in": 1440
}
Next refresh: 2020-10-01 11:20:22.151218
```
You can see that the OAuth server response includes the fields were highlighted in step 1. Now that we know how to retrieve an `access_token`, lets see how to refresh a token.

### 5. Refresh the `access_token` using the `refresh_token` mechanism

A different `grant_type` is required in the request (`refresh_token`), and we need to include the `refresh_token` value from the previous response in the payload. Besides that, the URL is exactly the same and we also need to include the `BASE64_AUTHSTRING` in the `Authorization` header.

```python
# Code from ariba_authentication.py script L69-75
payload = f'grant_type=refresh_token&refresh_token={refresh_token}'
headers = {
    'Authorization': f"Basic {BASE64_AUTHSTRING}",
    'Content-Type': 'application/x-www-form-urlencoded'
}

response = requests.request("POST", API_OAUTH_URL, headers=headers, data=payload)
```

:point_right: Now, that you know what is the difference between getting an access token and refreshing an access token when communicating with the SAP Ariba API OAuth server, go ahead and refresh the access token by running the following from command line:
```bash
$ python ariba_authentication.py --mode=refresh_token --verbose
```

The output of the command above will be similar to the following response:
```json
Refresh token response:
{
 "timeUpdated": 1601544024316,
 "access_token": "1dc0ad40-43ea-401f-a0f7-c4734962cbec",
 "refresh_token": "9223adc6-ca6c-40dd-9018-fcb16875a081",
 "token_type": "bearer",
 "scope": null,
 "expires_in": 1440
}
Next refresh: 2020-10-01 11:42:24.361207
```

You can see that there is an additional field when refreshing a token - `timeUpdated`, which informs us when was the token updated.

> In the case of the SAP Ariba APIs, it is possible to refresh an access token 2 minutes before it expires.

## Summary

You've made it to the end of this exercise :clap: :clap:. We've covered what we should expect as a response from an OAuth server, how to authenticate against the SAP Ariba API, what the differences are between access tokens and refresh tokens ... and finally, how to actually refresh an access token.


## Questions

1. What is encoded in the BASE64_AUTHSTRING value?
2. Can we authenticate against the API more than once (step 4)? What happens to the previous access_token received?
3. What happens if we try to refresh a token that has not expired and that will not expire soon? *Hint: Send a refresh token request after acquiring a new access token.*
4. What is the behaviour of the script if we run it with `--mode=loop` and no token exists? What if a token already exists?