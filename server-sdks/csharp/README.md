# GroupVAN C#/.NET Client Library

C#/.NET client for authenticating with GroupVAN V3 APIs using JWT tokens with RSA256.

## Installation

Using .NET CLI:
```bash
dotnet add package System.IdentityModel.Tokens.Jwt
dotnet add package Newtonsoft.Json
```

Using Package Manager:
```powershell
Install-Package System.IdentityModel.Tokens.Jwt
Install-Package Newtonsoft.Json
```

Or add to your .csproj:
```xml
<ItemGroup>
  <PackageReference Include="System.IdentityModel.Tokens.Jwt" Version="7.0.0" />
  <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
</ItemGroup>
```

## Quick Start

```csharp
using GroupVAN.Auth;

// Generate RSA key pair
var (privateKey, publicKey) = GroupVANClient.GenerateRSAKeyPair();

// Initialize client
using var client = new GroupVANClient(
    "your_developer_id",
    "your_key_id",
    privateKey  // RSA private key
);

// Generate JWT token
string token = client.GenerateJWT();

// Make API calls
var catalogs = await client.ListCatalogsAsync(10);
var catalog = await client.GetCatalogAsync("catalog_123");
```

## RSA Key Management

### Generate New Key Pair

```csharp
// Generate 2048-bit RSA key pair
var (privateKeyPem, publicKeyPem) = GroupVANClient.GenerateRSAKeyPair(2048);

// Save keys to files
File.WriteAllText("private_key.pem", privateKeyPem);
File.WriteAllText("public_key.pem", publicKeyPem);

Console.WriteLine("Public key to share with GroupVAN:");
Console.WriteLine(publicKeyPem);
```

### Load Existing Keys

```csharp
// Load private key from file
string privateKeyPem = File.ReadAllText("private_key.pem");

using var client = new GroupVANClient(
    "your_developer_id",
    "your_key_id",
    privateKeyPem
);
```

## JWT Token Generation

Tokens are automatically generated with these claims:

```json
{
    "aud": "groupvan",
    "iss": "your_developer_id",
    "kid": "your_key_id",
    "exp": 1234568190,  // 5 minutes from now
    "iat": 1234567890
}
```

With header:
```json
{
    "alg": "RS256",
    "typ": "JWT",
    "kid": "your_key_id",
    "gv-ver": "GV-JWT-V1"
}
```

Custom expiration:
```csharp
// Generate token with 10-minute expiration
string token = client.GenerateJWT(600);
```

## API Methods

### List Catalogs
```csharp
var catalogs = await client.ListCatalogsAsync(10, 0);
Console.WriteLine($"Found {catalogs.Items?.Count ?? 0} catalogs");
```

### Get Catalog
```csharp
var catalog = await client.GetCatalogAsync("catalog_123");
Console.WriteLine($"Catalog name: {catalog.name}");
```

### Create Catalog
```csharp
var newCatalog = await client.CreateCatalogAsync(new
{
    name = "New Catalog",
    type = "products",
    description = "Created from C# client"
});
Console.WriteLine($"Created catalog with ID: {newCatalog.id}");
```

### Custom Requests
```csharp
var response = await client.MakeAuthenticatedRequestAsync<dynamic>(
    HttpMethod.Post,
    "/catalogs",
    new
    {
        name = "New Catalog",
        type = "products"
    }
);
```

## Token Verification

Verify tokens using the public key (server-side operation):

```csharp
JwtSecurityToken validatedToken;
bool isValid = GroupVANClient.ValidateJWT(
    token,
    publicKeyPem,
    out validatedToken
);

if (isValid)
{
    Console.WriteLine("✓ Token verified successfully!");
    Console.WriteLine($"Expires at: {validatedToken.ValidTo}");
}
else
{
    Console.WriteLine("✗ Token verification failed");
}
```

## Environment Variables

```bash
export GROUPVAN_DEVELOPER_ID="your_developer_id"
export GROUPVAN_KEY_ID="your_key_id"
export GROUPVAN_PRIVATE_KEY_PATH="/path/to/private_key.pem"
export GROUPVAN_API_URL="https://api.groupvan.com/v3"
```

Load from environment:
```csharp
// Load private key from file
string privateKeyPem = File.ReadAllText(
    Environment.GetEnvironmentVariable("GROUPVAN_PRIVATE_KEY_PATH")
);

using var client = new GroupVANClient(
    Environment.GetEnvironmentVariable("GROUPVAN_DEVELOPER_ID"),
    Environment.GetEnvironmentVariable("GROUPVAN_KEY_ID"),
    privateKeyPem,
    Environment.GetEnvironmentVariable("GROUPVAN_API_URL") ?? "https://api.groupvan.com/v3"
);
```

## Error Handling

```csharp
try
{
    var catalog = await client.GetCatalogAsync("catalog_123");
}
catch (Exception ex)
{
    if (ex.Message.Contains("401"))
    {
        Console.WriteLine("Authentication failed - check your credentials");
    }
    else if (ex.Message.Contains("404"))
    {
        Console.WriteLine("Catalog not found");
    }
    else
    {
        Console.WriteLine($"Error: {ex.Message}");
    }
}
```

## Complete Example

```csharp
using System;
using System.Threading.Tasks;
using GroupVAN.Auth;
using System.IdentityModel.Tokens.Jwt;

class Program
{
    static async Task Main(string[] args)
    {
        Console.WriteLine(new string('=', 60));
        Console.WriteLine("GroupVAN JWT Authentication Example (RSA256)");
        Console.WriteLine(new string('=', 60));

        // Generate RSA keys
        var (privateKeyPem, publicKeyPem) = GroupVANClient.GenerateRSAKeyPair();
        
        Console.WriteLine("\nPublic Key (share with GroupVAN):");
        Console.WriteLine(publicKeyPem.Substring(0, 200) + "...");
        
        // Initialize client
        using var client = new GroupVANClient(
            "dev_abc123",
            "key_xyz789",
            privateKeyPem
        );
        
        // Generate token
        var token = client.GenerateJWT();
        Console.WriteLine($"\nGenerated Token: {token.Substring(0, 50)}...");
        
        // Decode token to show claims
        var handler = new JwtSecurityTokenHandler();
        var jsonToken = handler.ReadJwtToken(token);
        Console.WriteLine("\nToken Claims:");
        foreach (var claim in jsonToken.Claims)
        {
            Console.WriteLine($"  {claim.Type}: {claim.Value}");
        }
        
        // Verify token with public key
        JwtSecurityToken validatedToken;
        bool isValid = GroupVANClient.ValidateJWT(token, publicKeyPem, out validatedToken);
        Console.WriteLine($"\n✓ Token is valid: {isValid}");
        
        // Example API calls (uncomment to test)
        /*
        try
        {
            var catalogs = await client.ListCatalogsAsync(5);
            Console.WriteLine($"\nFound {catalogs.Items?.Count ?? 0} catalogs");
            
            if (catalogs.Items?.Count > 0)
            {
                var catalogId = catalogs.Items[0].Id;
                var catalog = await client.GetCatalogAsync(catalogId);
                Console.WriteLine($"First catalog: {catalog.name}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"API Error: {ex.Message}");
        }
        */
    }
}
```

## Running the Example

```bash
# Run the project
dotnet run

# Build and run
dotnet build
dotnet run --project Client.csproj
```

## API Reference

### Class: `GroupVANClient`

#### Constructor
```csharp
GroupVANClient(string developerId, string keyId, string privateKeyPem, string baseUrl = "https://api.groupvan.com/v3")
```
- `developerId`: Your developer ID
- `keyId`: Your key ID
- `privateKeyPem`: RSA private key in PEM format
- `baseUrl`: API base URL (optional)

#### Methods

- `GenerateJWT(int expiresIn = 300)`: Generate JWT token
- `MakeAuthenticatedRequestAsync<T>(HttpMethod method, string endpoint, object data = null, Dictionary<string, string> queryParams = null)`: Make API request
- `GetCatalogAsync(string catalogId)`: Get catalog by ID
- `ListCatalogsAsync(int limit = 10, int offset = 0)`: List catalogs
- `CreateCatalogAsync(object catalogData)`: Create new catalog

### Static Methods

#### `GenerateRSAKeyPair(int keySize = 2048)`
Generate RSA key pair
- Returns: Tuple of (privateKey, publicKey) in PEM format

#### `ValidateJWT(string token, string publicKeyPem, out JwtSecurityToken validatedToken)`
Verify JWT token with public key
- Returns: bool indicating if token is valid

#### `GenerateJWT(Dictionary<string, string> accessKey)`
Generate JWT without client instance
- `accessKey`: Dictionary with developer_id, key_id, and private_key
- Returns: JWT token string

## Models

### CatalogListResponse
```csharp
public class CatalogListResponse
{
    public List<Catalog> Items { get; set; }
    public int Total { get; set; }
    public int Limit { get; set; }
    public int Offset { get; set; }
}
```

### Catalog
```csharp
public class Catalog
{
    public string Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public string Type { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
```

## Dependencies

- `System.IdentityModel.Tokens.Jwt` - JWT token generation and validation
- `Newtonsoft.Json` - JSON serialization
- `System.Security.Cryptography` - RSA key operations
- .NET 6.0 or higher

## Security Notes

1. **Private Key Security**: Never commit private keys to version control
2. **Key Storage**: Use Azure Key Vault or similar in production
3. **Token Expiration**: Keep tokens short-lived (5-15 minutes)
4. **HTTPS Only**: Always use HTTPS in production
5. **Key Rotation**: Implement regular key rotation

## Troubleshooting

### Package not found error
```bash
dotnet restore
dotnet add package System.IdentityModel.Tokens.Jwt
```

### JWT verification error
- Ensure public key matches private key
- Verify token hasn't expired
- Check system time is synchronized

### Connection errors
- Verify API URL is correct
- Check network connectivity
- Ensure firewall allows HTTPS traffic

### .NET version error
- Requires .NET 6.0 or higher
- Check version: `dotnet --version`

## Testing

```bash
# Run tests
dotnet test

# Run with specific configuration
dotnet test --configuration Release

# Run with coverage
dotnet test --collect:"XPlat Code Coverage"
```

## Deployment

### Docker
```dockerfile
FROM mcr.microsoft.com/dotnet/runtime:7.0
WORKDIR /app
COPY bin/Release/net7.0/publish/ .
ENTRYPOINT ["dotnet", "GroupVAN.Client.dll"]
```

### Azure Functions
```csharp
[FunctionName("GenerateToken")]
public static string Run([HttpTrigger] HttpRequest req)
{
    var client = new GroupVANClient(
        Environment.GetEnvironmentVariable("DEVELOPER_ID"),
        Environment.GetEnvironmentVariable("KEY_ID"),
        Environment.GetEnvironmentVariable("PRIVATE_KEY")
    );
    return client.GenerateJWT();
}
```

## License

MIT License - See LICENSE file for details

## Support

For issues or questions, contact the GroupVAN API team at api@groupvan.com