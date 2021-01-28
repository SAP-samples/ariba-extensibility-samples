# Data pagination in the SAP Ariba APIs

> This content was originally created as an exercise for the [Devtoberfest Cloud APIs event](https://github.com/SAP-samples/cloud-apis-virtual-event/) - [Exercise 08](https://github.com/SAP-samples/cloud-apis-virtual-event/tree/main/exercises/08).

Now that we know how to authenticate against the SAP Ariba APIs, we'll be looking at how to retrieve large amounts of data by using a mechanism known as pagination. Pagination is commonly used by APIs to limit the amount of data returned in a response. Limiting the data in the response normally improves the APIs performance, ensuring that the request response doesn't take a long time or returning unnecessary data to the client.

## Steps

After completing the steps in this exercise you'll know what pagination in an API is, what a pagination token (`pageToken`) is used for and how pagination has been implemented in the SAP Ariba APIs.

:point_right: To run the Python scripts included in this exercise, ensure that you checkout the [exercise-specific prerequisites](prerequisites.md).

### 1. Get familiar with how pagination works

If you are not familiar with the concept of pagination in an API, I can bet you that you've used some form of pagination in the past. When interacting with a search engine, you've entered your search query, e.g. [SAP Devtoberfest](https://github.com/SAP-samples/sap-devtoberfest-2020), click the :mag_right: button and the web page renders some results. It is possible that the search engine has thousands of results for your search query, but it will only display the first 10 results. If you want more results, you will need to click page :two:. Still unable to find what you are after, click page :three: and so on.

 Pagination in an API works pretty much the same but instead of clicking, we programatically specify which page we want to retrieve. The API response is batched and paginated, the results are returned one page at a time.

Unfortunately, there is no standard way APIs implement pagination but the process followed by APIs is very similar. The first request to the API, will only specify the data that the client is interested in. The API returns a subset of the data available and it informs the client that it has only returned part of the data. It does this by means of a "pagination token". This pagination token is returned in the response of the request, some APIs include it in the HTTP response headers, others in the body of the response. If the client is interested in retrieving more data, that matches its filtering criteria, it needs to include the pagination token in the request, to indicate to the API which page/batch of data it wants to retrieve.

:point_right: Navigate to the help documentation of the SAP Ariba [Analytical Reporting API](https://help.sap.com/viewer/bf0cde439a0142fbbaf511bfac5b594d/latest/en-US/1f8247e9e767438c8f18db7973779eaf.html) and get familiar with how we can invoke the Analytical Reporting [synchronous API](https://help.sap.com/viewer/bf0cde439a0142fbbaf511bfac5b594d/latest/en-US/e8f72dd7ea794de7b06417aa32e4524d.html). Ask yourself the following: how can I know the total number of records available for my request? How can I request additional batches of data?

We'll use the diagram below to explain how pagination works in the SAP Ariba API ([Analytical Reporting API](https://help.sap.com/viewer/bf0cde439a0142fbbaf511bfac5b594d/latest/en-US/1f8247e9e767438c8f18db7973779eaf.html)) that you'll be using in the exercise. In this API, the pagination token is specified as a query parameter in the URL, e.g. `https://openapi.ariba.com/api/analytics-reporting-details/v1/prod/views/SourcingProjectSourcingSystemView?pageToken=[TOKEN_VALUE]`.

> :warning: In the diagram below, I'm using api.ariba.com/report as the domain for convenience. This is not the URL of the Analytical Reporting API.

```
     +--------+                                                      +------------+
     |        |--(1)------- api.ariba.com/report?pageToken=    ----->| Reporting  |
     |        |                                                      | Data (API) |
     |        |<-(2)----- Response includes PageToken: QmF0Y2gxCg ---|            |
     |        |                                                      +------------+
     |        |
     |        |                                                      +------------+
     |        |--(3)--- api.ariba.com/report?pageToken=QmF0Y2gxCg -->| Reporting  |
     | Client |                                                      | Data (API) |
     |        |<-(4)----- Response includes PageToken: MkJhdGNoCg ---|            |
     |        |                                                      +------------+
     |        |
     |        |                                                      +------------+
     |        |--(5)--- api.ariba.com/report?pageToken=MkJhdGNoCg -->| Reporting  |
     |        |                                                      | Data (API) |
     |        |<-(6)---------- No PageToken in response -------------|            |
     +--------+                                                      +------------+
```

Sequence:
1. The client sends a request to the API with no `pageToken`. Given that the `pageToken` is empty, the query parameter can be omitted.
2. The server response returns the first batch (page) of data and includes a PageToken (QmF0Y2gxCg) in the response body. The client will need to include this token in the next request if it wants to retrieve another batch of data.
3. The client sends the same request but it now includes the token sent by the server -> `pageToken=QmF0Y2gxCg`.
4. The server response returns the second batch of data and includes a new PageToken (MkJhdGNoCg).
5. The client sends the same request but it now includes the second token retrieved -> `pageToken=MkJhdGNoCg`.
6. The server response returns the third batch of data but this time there is no PageToken in the response, meaning that this is the last batch of data available for our request. No subsequent requests are needed to retrieve all the results.

By now, you should have a good understanding of the basic concepts around data pagination in an API and how you can paginate in the SAP Ariba API you'll be using in this exercise.

### 2. Set up the SAP Ariba API details in script

Lets look at some code now. Before sending a request we will specify the application details previously shared by an SAP Ariba developer portal administrator in our environment configuration. In this step, we will use the [ariba_authentication.py](../07/scripts/ariba_authentication.py) script introduced in [exercise 07](../07/) to handle the authentication needed for this exercise.

:point_right: Navigate to the [scripts folder](../07/scripts/) in exercise 07 and copy the [ariba_authentication.py](../07/scripts/ariba_authentication.py) file to the [scripts folder](scripts/) in this exercise.

The Python script uses [python-dotenv](https://pypi.org/project/python-dotenv/) to set some environment variable required by the script.

:point_right: Navigate to the scripts folder and create a file called `.env`. Copy and paste the sample config settings shown below and replace the values of `REALM`, `API_OAUTH_URL`, `API_KEY`, `BASE64_AUTHSTRING` and maybe `API_URL` with the values provided by your administrator.

> For a detailed explanation of the SAP Ariba developer portal, creating an application and its approval process, checkout the [SAP Ariba for developers YouTube playlist :tv:](https://www.youtube.com/watch?v=oXW3SBCadoI&list=PL6RpkC85SLQDXSLHrSPtu8wztzDs8kYPX)

The contents of the new .env file should look similar to the one below:
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
API_URL=https://openapi.ariba.com/api/analytics-reporting-details/v1/prod
```

### 3. Explore the [`ariba_pagination.py`](scripts/ariba_pagination.py) script

:point_right: Go to the scripts folder, open the [`ariba_pagination.py`](scripts/ariba_pagination.py) file and go through the code.

The [`ariba_pagination.py`](scripts/ariba_pagination.py) script, included in this exercise, was created to facilitate completing the exercise. It retrieves the `access_token` from the credentials stored by the ariba_authentication.py script. The `access_token` will be used to retrieve data from the Analytical reporting API. To keep things simple, we will be using in this exercise the SourcingProjectSourcingSystemView template, which is available out of the box in SAP Ariba.

The script can be run in the following modes (by specifying the `--mode` parameter):
- `count`: Gets how many records will be included in the results set for a query using the `SourcingProjectSourcingSystemView` template.
- `paginate`: This is the default mode. Uses the previously retrieved access token to get a new access token from the OAuth server.

It is possible to specify the view template (`--view_template` parameter) and the filter criteria (`--filters` parameter) of the data that you want to extract.
- `--view_template`: By default it will use the `SourcingProjectSourcingSystemView` view template, which is available out of the box in SAP Ariba.
- `--filters`: The script expects a JSON structure to define the filter criteria, e.g. `'{"createdDateFrom":"2019-07-07T00:00:00Z","createdDateTo":"2020-07-06T00:00:00Z"}'`

### 4. Find out how many records we can retrieve using the view template + filter combination

The code sample below shows how we can call the SAP Ariba Analytical Reporting API to retrieve data from the view templates available in the realm.

> Given that the filters are passed as a query parameter, it is important to encode them as it might include special characters, e.g. {, }

```python
# Code from ariba_pagination.py script L62-84
headers = {
     'Authorization': f"Bearer {get_access_token()}",
     'apiKey': API_KEY
}

request_url = f"{API_URL}/views/{view_template}{path}?realm={REALM}&filters={urllib.parse.quote(filters)}"

if page_token is not None:
     request_url += f"&pageToken={page_token}"

response = requests.request("GET", request_url, headers=headers)
```

:point_right: Now you know how the script sends request to the SAP Ariba Analytical Reporting API. Lets find how many records are available for our view template + filter combination, go ahead and `count` the view template by running the following command line:

```bash
$ python ariba_pagination.py --mode count --view_template SourcingProjectSourcingSystemView --filters '{"createdDateFrom":"2019-07-07T00:00:00Z","createdDateTo":"2020-07-06T00:00:00Z"}'
```

Depending on the amount of data available, the output of the command above will be similar to the below:
```bash
==========================
👉 Request URL: https://openapi.ariba.com/api/analytics-reporting-details/v1/prod/views/SourcingProjectSourcingSystemView/count?realm=MyRealm-T&filters=%7B%22createdDateFrom%22%3A%222019-07-07T00%3A00%3A00Z%22%2C%22createdDateTo%22%3A%222020-07-06T00%3A00%3A00Z%22%7D
==========================
Maximum records per page: 10000
Total number of pages in result set: 1
Total number of records in result set: 135
```

You can see that there are 135 records available. Let's now look at how we can retrieve the data.

### 5. Paginate the records available for your view template + filter combination

It is possible that there is a lot of data available for your view template + filter combination. In that case, it will not be possible to retrieve all data at once and you will need to "paginate" the response. Every page retrieved will contain a subset of the data.

:point_right: Now, that you know how many records are available for our view template + filter combination, go ahead and `paginate` the view template by running the following command line:

```bash
$ python ariba_pagination.py --mode paginate --view_template SourcingProjectSourcingSystemView --filters '{"createdDateFrom":"2019-07-07T00:00:00Z","createdDateTo":"2020-07-06T00:00:00Z"}'
```

Depending on the amount of data available, the output of the command above will be similar to the below:
```bash
==========================
👉 Request URL: https://openapi.ariba.com/api/analytics-reporting-details/v1/prod/views/SourcingProjectSourcingSystemView?realm=MyRealm-T&filters=%7B%22createdDateFrom%22%3A%222019-07-07T00%3A00%3A00Z%22%2C%22createdDateTo%22%3A%222020-07-06T00%3A00%3A00Z%22%7D&pageToken=
==========================
Current iteration: 0
Total number of records in response: 50
Next page: QUlwY0FHN0NxVnA3ZE90
==========================
👉 Request URL: https://openapi.ariba.com/api/analytics-reporting-details/v1/prod/views/SourcingProjectSourcingSystemView?realm=MyRealm-T&filters=%7B%22createdDateFrom%22%3A%222019-07-07T00%3A00%3A00Z%22%2C%22createdDateTo%22%3A%222020-07-06T00%3A00%3A00Z%22%7D&pageToken=QUlwY0FHN0NxVnA3ZE90
==========================
Current iteration: 1
Total number of records in response: 50
Next page: QUlwY0FHN0RJRTZURGlr
==========================
👉 Request URL: https://openapi.ariba.com/api/analytics-reporting-details/v1/prod/views/SourcingProjectSourcingSystemView?realm=MyRealm-T&filters=%7B%22createdDateFrom%22%3A%222019-07-07T00%3A00%3A00Z%22%2C%22createdDateTo%22%3A%222020-07-06T00%3A00%3A00Z%22%7D&pageToken=QUlwY0FHN0RJRTZURGlr
==========================
Current iteration: 2
Total number of records in response: 35
Next page: STOP
Finished!
```

> If you want to store the API response(s) locally, pass the --save parameter when invoking the ariba_pagination.py script, e.g. `python ariba_pagination.py --mode count --view_template SourcingProjectSourcingSystemView --filters '{"createdDateFrom":"2019-07-07T00:00:00Z","createdDateTo":"2020-07-06T00:00:00Z"}' --save`.

## Summary

You've made it to the end of this exercise :clap: :clap:. We've covered what pagination is and how it has been implemented in the SAP Ariba APIs. Also, we know where to look for a pagination token and how to include it in a request.


## Questions

1. Apart from a search engine, can you think of other application(s) where you've been presented with "pages" of data.
2. What is the SAP Ariba Analytical Reporting API rate limit?
3. What is the default page size when retrieving analytical reporting data? How can you specify a different value?
