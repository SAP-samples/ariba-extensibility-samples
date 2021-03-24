# Consume Ariba APIs from ABAP

In this sample you will learn how to consume Ariba APIs using classical ABAP objects.

The SAP Ariba APIs allows creating integrations between applications/services/machines. The APIs are commonly used to extend the capabilities of SAP Ariba, e.g. extend approval process, interact with invoices, or it can just be to retrieve transactional/analytical data from the SAP Ariba realm (instance).

To allow programmatic access to an SAP Ariba realm, an application will need to be created in the [SAP Ariba developer portal](https://developer.ariba.com) and go through the application approval process. Once the approval process completes, the developer portal administrator will be able to generate OAuth credentials for the application. These OAuth credentails are required to complete this exercise.

## Steps

After completing the steps in this exercise you'll know how to consume an SAP Ariba API from classical ABAP.

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

### 2. Set up the SAP Ariba API details in the ABAP class

Before sending an API request, we need to specify the application details previously shared by an SAP Ariba developer portal administrator in our environment configuration.

> For a detailed explanation of the SAP Ariba developer portal, creating an application and its approval process, checkout the [SAP Ariba for Developers YouTube playlist :tv:](https://www.youtube.com/watch?v=oXW3SBCadoI&list=PL6RpkC85SLQDXSLHrSPtu8wztzDs8kYPX)

In the private section of the class, there are several global constants pre-defined to be able to consume an API. The values of those constants must be changed:

- `gc_api_name`: The name of the API to be stored in the Z table
- `gc_apikey`: The API key of the app registered in the Ariba developer portal
- `gc_oauth_secret`: The OAuth secret of the app registered in the Ariba developer portal
- `gc_get_token_body`: The Get Token API body. You shouldn't change it
- `gc_refresh_token_body`: The Refresh Token API body. You shouldn't change it
- `gc_realm`: The realm name
- `gc_viewname`: The view name to consume in the report
- `gc_token_destination`: The RFC destination with the URL for the Token API
- `gc_api_destination`: The RFC destination with the URL for the API

### 3. Run the class in SE24

You can now go ahead an run the class in transaction `SE24`. Just call method `ANALYTICAL_SYNCHRONOUS` and you should see the result.

## Summary

You should now be able to consume SAP Ariba APIs from ABAP. If you want to know more about JSON transformation and how to handle it, you can check this Wiki for [One more ABAP to JSON Serializer and Deserializer](https://wiki.scn.sap.com/wiki/display/Snippets/One+more+ABAP+to+JSON+Serializer+and+Deserializer)