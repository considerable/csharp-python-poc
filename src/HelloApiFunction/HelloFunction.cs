using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;

namespace HelloApiFunction;

public class HelloFunction
{
    [Function("HelloApi")]
    public IActionResult Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "hello")]
        HttpRequest req)
    {
        return new OkObjectResult(new
        {
            message = "Hello from Azure Functions!",
            service = "hello-api"
        });
    }
}