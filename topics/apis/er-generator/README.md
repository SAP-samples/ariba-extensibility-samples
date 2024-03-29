# Entity Relationship generator for SAP Ariba Analytical Reporting API metadata

The metadata endpoint of the SAP Ariba Analytical Reporting API will return details of all the facts and dimensions we can use to create our view templates. Although all the available facts and dimensions are returned by the API, it can be hard to navigate the JSON payload and understand the relationship(s) between facts and dimensions. The Python script in this repo, was created to generate an ER diagram and easily visualise the relationship(s) a fact/dimension has.

⚡ Retrieve the Analytical Reporting metadata available for your realm, you can run the curl command below.

```bash
$ curl --location --request GET 'https://openapi.ariba.com/api/analytics-reporting-view/v1/prod/metadata?realm=[YOUR-REALM-T]&product=analytics&includePrimaryKeys=true' \
--header 'apiKey: [YOUR-API-KEY]' \
--header 'Authorization: Bearer [YOUR-ACCESS-TOKEN]' > AnalyticalReportingMetadata.json
```

⚡ “pip install” the packages included in requirements.txt before running the script.

```bash
$ pip install -r requirements.txt
```

⚡ Run the Python script

```bash
$ python generate_er_diagram.py --document_type ApprovalHistoryFact
```

### Docker image/container

A Dockerfile is now included in the folder. You can build the docker image and communicate with the program via your browser.

```bash
# Build docker image
$ docker build --tag er-generator .

# Run docker image
$ docker run -p 8080:5000 er-generator
```

Once the docker container is running, you can call the program from your web browser
- Get all document types: http://localhost:8080/documentTypes
- Get diagram for a document type: http://localhost:8080/documentTypes/CatalogReportingEntryFact/diagram

### Deploy to Kyma runtime

To deploy the image to Kyma, we will need to host the image in a private repo. 
```bash
# Login to private repo locally
$ docker login --username user registry.mycompany.com

# Tag previously created image with repo
$ docker tag [IMAGE_ID] registry.mycompany.com/ariba-reporting-er-generator

# Push to private repo
$ docker push registry.mycompany.com/ariba-reporting-er-generator
```

Now, deploy to Kyma
```bash
# Create secret to login to the private repository
$ kubectl create secret docker-registry docker-registry-secret --docker-server=registry.mycompany.com --docker-username=user --docker-password=StrongP4$sw0rd1 --docker-email=first.last@mycompany.com --namespace=default

# Apply deployment, service and API rule
$ kubectl apply -f kyma/deployment.yml
$ kubectl apply -f kyma/service.yml
$ kubectl apply -f kyma/api-rule.yml
```

Some sample diagrams are included in the [sample-diagrams](./sample-diagrams) folder.