# SAP Ariba API recipes

When utilising the SAP Ariba APIs, not all data can be retrieved from a single API call or certain actions require interacting with multiple APIs. The idea is that the "recipes" included here can show you how you can achieve common tasks carried out by developers to retrieve specific pieces of data or carry out certain actions, by combining calls to various APIs available.

In this folder, you'll find various "recipes" that you can follow to retrieve data or carry out actions from/in the SAP Ariba APIs. Each recipe will be presented in a separate [Jupyter notebook](https://jupyter.org/). Each notebook will contain details of the different SAP Ariba APIs used to achieve a specific goal, sample URLs and responses from the SAP Ariba API.

**Why using a Jupyter notebook?**

The Jupyter Notebook is an open-source web application that allows you to create and share documents that contain live code, equations, visualizations and narrative text. Uses include: data cleaning and transformation, numerical simulation, statistical modeling, data visualization, machine learning, and much more.

In our case, they are used to explore the SAP Ariba API. When navigating the Jupyter notebook, the user can see the thought process the author of the recipe went through to complete the goal. As mentioned before, the notebook will contain the URLs used to invoke the API, links to documentation and sample JSON payloads/responses.

## Recipes:

- [Asynchronous Reporting API - Submit and process async job requests](./async-reporting-api-submit-process-job.ipynb)
- [Retrieve Sourcing Requests from SAP Ariba API](./retrieve-sourcing-requests-from-api.ipynb)
- [Invoice Extractor from the AN API](./retrieve-invoices-aribanetwork-api.ipynb)
- Get documents from a Contract Workspace (coming soon)
- Download attachments from a supplier questionnaire (coming soon)
