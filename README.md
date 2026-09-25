# C# Azure Functions DevOps POC

A small end-to-end DevOps / Platform Engineering proof of concept demonstrating how a simple application can move from source code to a deployed Azure service using **Terraform and Azure DevOps**.

The application is intentionally simple. The focus of the POC is the delivery path: infrastructure, application build, packaging, deployment, and post-deployment validation.

## What this demonstrates

* C to C#/.NET application transition
* .NET 10 Azure Functions isolated worker
* Azure Functions Flex Consumption
* Terraform infrastructure as code
* Azure DevOps CI/CD
* Automated application packaging
* Azure RBAC for the deployment service principal
* Application Insights integration
* Post-deployment smoke testing
* Separation of infrastructure provisioning from application deployment

## Architecture

```text
                         Terraform
                            |
                            v
                  +--------------------+
                  | Azure Resource     |
                  | Group              |
                  +--------------------+
                     |    |    |    |
                     |    |    |    +-- Application Insights
                     |    |    +------- Log Analytics
                     |    +------------ Storage
                     +----------------- Function App
                                      |
                                      v
                            Azure Functions
                            Flex Consumption
                                      |
                                      |
                         GET /api/hello
                                      |
                                      v
                         JSON response


Azure DevOps Pipeline

    Source
      |
      v
  dotnet restore
      |
      v
  dotnet build
      |
      v
  dotnet publish
      |
      v
  ZIP package
      |
      v
  Azure Function deployment
      |
      v
  HTTP smoke test
```

## Application

The application exposes one HTTP endpoint:

```text
GET /api/hello
```

Example response:

```json
{
  "message": "Hello from Azure Functions!",
  "service": "hello-api"
}
```

The current application is implemented as a **C# .NET 10 isolated-worker Azure Function**.

The HTTP server, socket management, TLS termination, and Function hosting are provided by Azure Functions. The application code is responsible only for the function itself.

## C prototype

The project originally started with a small standalone HTTP server written in C.

The C prototype implements the same basic API using POSIX sockets:

```text
GET /api/hello
```

and returns the same JSON payload.

The prototype is retained under:

```text
src/HelloApiPrototype/hello-api.c
```

The C program is a standalone HTTP server, while the C# implementation is an Azure Function and therefore does not create or manage its own socket.

The transition demonstrates the difference between implementing an HTTP service directly and moving the application logic into a managed serverless runtime.

## Infrastructure

Terraform provisions the Azure resources required by the application.

Current infrastructure includes:

* Azure Resource Group
* Azure Storage Account
* Blob container for Function deployment storage
* Flex Consumption service plan
* Azure Function App
* System-assigned managed identity
* Log Analytics workspace
* Application Insights
* Azure RBAC assignment for the Azure DevOps deployment service principal

The Function App is configured for:

```text
Runtime:       .NET isolated
Version:       .NET 10
Hosting:       Flex Consumption
OS:            Linux
HTTPS:         Enabled
TLS:           1.2 minimum
```

Terraform is responsible for **infrastructure**.

Azure DevOps is responsible for **application deployment**.

That separation is intentional.

## CI/CD

The Azure DevOps pipeline performs the following steps:

1. Install the .NET 10 SDK
2. Restore dependencies
3. Build the application
4. Publish the application
5. Create a deployment ZIP
6. Publish the ZIP as a pipeline artifact
7. Deploy the application to Azure Functions
8. Execute an HTTP smoke test

The deployment uses:

```yaml
AzureFunctionApp@2
```

with Flex Consumption deployment enabled.

The pipeline is defined in:

```text
azure-pipelines.yml
```

## Deployment validation

After deployment, the pipeline calls:

```text
GET https://helloapifunc-demo.azurewebsites.net/api/hello
```

The smoke test verifies both that the endpoint is reachable and that the returned payload identifies the expected service.

This prevents a successful deployment task from being treated as proof that the application itself is working.

## Repository structure

```text
.
├── README.md
├── azure-pipelines.yml
├── .gitignore
├── Makefile
│
├── src
│   ├── HelloApiFunction
│   │   ├── HelloApiFunction.csproj
│   │   ├── HelloFunction.cs
│   │   ├── Program.cs
│   │   ├── host.json
│   │   └── local.settings.json
│   │
│   └── HelloApiPrototype
│       └── hello-api.c
│
├── terraform
│   └── main.tf
│
├── docker
│   └── Dockerfile
│
├── python
│   └── wheelhouse
│       └── .gitkeep
│
└── scripts
    └── get-pipeline-log.sh
```

Some directories are retained from earlier POC experiments. The production deployment path demonstrated by the current POC is:

```text
.NET
  +
Terraform
  +
Azure DevOps
  +
Azure Functions Flex Consumption
```

Docker and the Python wheelhouse are not required for the current Azure deployment.

## Technology

### Application

* C#
* .NET 10
* Azure Functions
* Isolated Worker Model
* HTTP/JSON

### Cloud

* Microsoft Azure
* Azure Functions Flex Consumption
* Azure Storage
* Application Insights
* Log Analytics
* Azure RBAC

### Infrastructure

* Terraform
* AzureRM provider
* Infrastructure as Code

### CI/CD

* Azure DevOps Pipelines
* YAML pipeline
* AzureFunctionApp@2
* Azure CLI
* Linux hosted build agent

### Development

* Git
* Bash
* C
* Docker
* Python packaging concepts

## Design decisions

### Terraform vs. pipeline deployment

Terraform creates and configures the Azure environment.

The CI/CD pipeline deploys application versions.

This avoids using Terraform as an application deployment mechanism and keeps infrastructure lifecycle separate from application lifecycle.

### Managed Azure Functions hosting

The C# application does not implement its own HTTP server.

Azure Functions provides the hosting layer, allowing the application to focus on the HTTP-triggered function.

### Simple application

The application intentionally contains very little business logic.

The purpose of this POC is not to demonstrate application complexity. It is to demonstrate a repeatable path from source code to a running cloud service.

## Local development

The Function application can be built with:

```bash
cd src/HelloApiFunction

dotnet restore
dotnet build
dotnet publish --configuration Release
```

The C prototype can be compiled independently with a standard C compiler on a Unix-like system.

## Security considerations

No credentials or secrets are stored in the repository.

Environment-specific Terraform values are supplied separately and should not be committed.

The Azure DevOps service principal receives the required Azure RBAC permissions through Terraform.

The deployed Function App uses HTTPS and a minimum TLS version of 1.2.

## Status

The POC currently demonstrates a complete path:

```text
Source
  ↓
Build
  ↓
Package
  ↓
Azure DevOps artifact
  ↓
Azure Functions deployment
  ↓
HTTP smoke test
  ↓
Running service
```

The application is intentionally small so that the CI/CD and infrastructure implementation remain easy to inspect.

## Purpose

This repository is a technical demonstration of practical DevOps and platform engineering work:

* infrastructure defined as code
* repeatable CI/CD
* cloud resource provisioning
* application packaging
* controlled deployment
* RBAC
* observability integration
* automated validation
* clear separation between infrastructure and application delivery
