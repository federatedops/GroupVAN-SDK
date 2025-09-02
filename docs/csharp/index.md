---
layout: default
title: C#/.NET
nav_order: 7
has_children: true
---

# C#/.NET Client Library
{: .no_toc }

Complete documentation for the GroupVAN C#/.NET client library.
{: .fs-6 .fw-300 }

---

## Installation

### Requirements
- .NET 6.0 or higher (or .NET Standard 2.0 compatible framework)
- NuGet package manager

### Install via NuGet

```bash
# .NET CLI
dotnet add package GroupVAN.Client

# Package Manager Console
Install-Package GroupVAN.Client

# PackageReference
<PackageReference Include="GroupVAN.Client" Version="1.0.0" />
```

## Quick Example

```csharp
using GroupVAN.Client;

// Initialize client
var client = new GroupVANClient(
    developerId: "DEV123",
    keyId: "KEY001",
    privateKeyPath: "/path/to/private_key.pem"
);

// Generate JWT token
var token = client.GenerateToken();

// Make API call
var response = await client.ApiCallAsync(
    HttpMethod.Get,
    "/api/v3/users",
    token
);

Console.WriteLine(response);
```

## Configuration

### Using AppSettings

```json
// appsettings.json
{
  "GroupVAN": {
    "DeveloperId": "DEV123",
    "KeyId": "KEY001",
    "PrivateKeyPath": "/path/to/private_key.pem"
  }
}
```

```csharp
var configuration = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .Build();

var client = new GroupVANClient(configuration);
```

### Using Environment Variables

```csharp
// Automatically reads from environment
var client = GroupVANClient.FromEnvironment();
// Looks for:
// - GROUPVAN_DEVELOPER_ID
// - GROUPVAN_KEY_ID
// - GROUPVAN_PRIVATE_KEY_PATH
```

## API Reference

### Constructor Parameters

| Parameter | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `developerId` | string | Yes | Your GroupVAN developer ID |
| `keyId` | string | Yes | Your key identifier |
| `privateKeyPath` | string | No* | Path to private key file |
| `privateKey` | string | No* | Private key content |
| `baseUrl` | string | No | API base URL |
| `timeout` | TimeSpan | No | Request timeout |

### Methods

#### GenerateToken(options)
Generate a JWT token for API authentication.

```csharp
var token = client.GenerateToken(new TokenOptions
{
    ExpirationMinutes = 5, // optional, default: 5
    AdditionalClaims = new Dictionary<string, object>() // optional
});
```

#### ApiCallAsync(method, endpoint, token, options)
Make an authenticated API call.

```csharp
var response = await client.ApiCallAsync(
    HttpMethod.Post,
    "/api/v3/users",
    token,
    new ApiCallOptions
    {
        Data = new { Name = "John Doe" },
        QueryParams = new { Page = 1 },
        Headers = new Dictionary<string, string>()
    }
);
```

## Error Handling

```csharp
try
{
    var token = client.GenerateToken();
    var response = await client.ApiCallAsync(
        HttpMethod.Get,
        "/api/v3/users",
        token
    );
}
catch (AuthenticationException ex)
{
    Console.WriteLine($"Authentication failed: {ex.Message}");
}
catch (ApiException ex)
{
    Console.WriteLine($"API call failed: {ex.Message}");
    Console.WriteLine($"Status code: {ex.StatusCode}");
}
```

## Dependency Injection

```csharp
// Startup.cs or Program.cs
services.AddSingleton<IGroupVANClient>(provider =>
{
    var config = provider.GetRequiredService<IConfiguration>();
    return new GroupVANClient(
        config["GroupVAN:DeveloperId"],
        config["GroupVAN:KeyId"],
        config["GroupVAN:PrivateKeyPath"]
    );
});

// In your service
public class MyService
{
    private readonly IGroupVANClient _client;
    
    public MyService(IGroupVANClient client)
    {
        _client = client;
    }
}
```

## Resources

- [Source Code](https://github.com/federatedops/groupvan-api-client/tree/main/clients/csharp)
- [NuGet Package](https://www.nuget.org/packages/GroupVAN.Client)
- [Examples](https://github.com/federatedops/groupvan-api-client/tree/main/examples/csharp)