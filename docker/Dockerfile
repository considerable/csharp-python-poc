FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/HelloApiFunction/. ./src/HelloApiFunction/
WORKDIR /src/src/HelloApiFunction
RUN dotnet restore && dotnet publish --configuration Release --output /publish

FROM mcr.microsoft.com/azurefunctions/dotnet-isolated:4-dotnet-isolated10.0 AS runtime
WORKDIR /home/site/wwwroot

COPY --from=build /publish /home/site/wwwroot

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

EXPOSE 80
CMD ["/azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost"]
