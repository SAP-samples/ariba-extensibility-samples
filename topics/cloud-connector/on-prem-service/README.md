# On-premise mock service

The on-premise mock service included in this repository is a simple [Cloud Application Programming (CAP) model](https://cap.cloud.sap/docs/) Node.js application. The idea is to simulate an on-premise system that exposes an API and can receive requests from other 3rd party systems. Access to this service is what is configured in the Replicate SAP Ariba data to an on-premise service using SAP Cloud Integration and SAP Cloud Connector [exercise](../README.md) to allow communication from SAP BTP to the service running locally.

## Set up local environment

To run the mock service, we need to have [Node.js](https://nodejs.org/) and [npm](https://www.npmjs.com/get-npm) installed in our system. To check if Node.js and npm are installed, run the following command in your terminal:

```bash
$ node -v
$ npm -v
```

If any of the commands above gives an error, make sure to install Node.js/npm from https://nodejs.org/en/.

Once installed, run the following commands:
```bash
$ npm install
$ cds watch
```

The service will start and it will be ready to receive requests. To validate that it is working, open a browser and navigate to http://localhost:4004/mock/Suppliers. A list of dummy suppliers will be returned by the service.

## Entities

The entities exposed by the mock service are included in [srv/mock-service.cds](srv/mock-service.cds). 

The `SourcingProjects` entity is currently being used in the Replicate SAP Ariba data to an on-premise service using SAP Cloud Integration and SAP Cloud Connector [exercise](../README.md), expects a request like the one below:
```bash
$ curl --location --request POST 'http://localhost:4004/mock/SourcingProjects' \
--header 'Content-Type: application/json' \
--data-raw '{
"ID": "WS1858855273",
"Title": "My Sourcing Project",
"Status": "Active",
"ParentDocumentId": "SYS0003",
"ExternalSystemCorrelationId": "",
"OwnerEmail": "aribacustomersupportadmin@sap.com"
}'
```

## Learn More

To learn more about the Cloud Application Programming model visit https://cap.cloud.sap/docs/get-started/ or check out the tutorials available at https://developers.sap.com/tutorial-navigator.html?tag=software-product-function:sap-cloud-application-programming-model.
