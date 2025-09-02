using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.IdentityModel.Tokens;
using Newtonsoft.Json;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace GroupVAN.Auth
{
    /// <summary>
    /// GroupVAN JWT Authentication Client for C#/.NET
    /// 
    /// This example demonstrates how to generate JWTs and make authenticated
    /// requests to V3 APIs using JWT authentication with RSA256.
    /// 
    /// Installation (NuGet):
    ///   Install-Package System.IdentityModel.Tokens.Jwt
    ///   Install-Package Newtonsoft.Json
    ///   Install-Package System.Security.Cryptography.Algorithms
    /// 
    /// Or via .NET CLI:
    ///   dotnet add package System.IdentityModel.Tokens.Jwt
    ///   dotnet add package Newtonsoft.Json
    /// </summary>
    public class GroupVANClient : IDisposable
    {
        private readonly string _developerId;
        private readonly string _keyId;
        private readonly RSA _privateKey;
        private readonly string _baseUrl;
        private readonly HttpClient _httpClient;

        /// <summary>
        /// Initialize the client with developer credentials
        /// </summary>
        /// <param name="developerId">Your developer ID</param>
        /// <param name="keyId">Your key ID</param>
        /// <param name="privateKeyPem">Your RSA private key in PEM format</param>
        /// <param name="baseUrl">API base URL (optional)</param>
        public GroupVANClient(string developerId, string keyId, string privateKeyPem, 
            string baseUrl = "https://api.groupvan.com/v3")
        {
            _developerId = developerId;
            _keyId = keyId;
            _privateKey = LoadPrivateKeyFromPem(privateKeyPem);
            _baseUrl = baseUrl;
            _httpClient = new HttpClient
            {
                BaseAddress = new Uri(baseUrl),
                Timeout = TimeSpan.FromSeconds(30)
            };
        }

        /// <summary>
        /// Generate a JWT token for authentication using RSA256
        /// </summary>
        /// <param name="expiresIn">Token expiry in seconds (default 300)</param>
        /// <returns>Signed JWT token</returns>
        public string GenerateJWT(int expiresIn = 300)
        {
            var securityKey = new RsaSecurityKey(_privateKey);
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.RsaSha256);

            // Create JWT claims
            var claims = new List<Claim>
            {
                new Claim("aud", "groupvan"),
                new Claim("iss", _developerId),
                new Claim("kid", _keyId),
                new Claim("iat", DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64),
                new Claim("exp", DateTimeOffset.UtcNow.AddSeconds(expiresIn).ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64)
            };

            // Create token with custom header
            var tokenHandler = new JwtSecurityTokenHandler();
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                SigningCredentials = credentials,
                IssuedAt = DateTime.UtcNow,
                Expires = DateTime.UtcNow.AddSeconds(expiresIn),
                AdditionalHeaderClaims = new Dictionary<string, object>
                {
                    { "kid", _keyId },
                    { "gv-ver", "GV-JWT-V1" }
                }
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        /// <summary>
        /// Alternative JWT generation method
        /// </summary>
        public static string GenerateJWT(Dictionary<string, string> accessKey)
        {
            var developerId = accessKey["developer_id"];
            var keyId = accessKey["key_id"];
            var privateKeyPem = accessKey["private_key"];

            var privateKey = LoadPrivateKeyFromPem(privateKeyPem);
            var securityKey = new RsaSecurityKey(privateKey);
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.RsaSha256);

            var currentTime = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

            var claims = new List<Claim>
            {
                new Claim("aud", "groupvan"),
                new Claim("iss", developerId),
                new Claim("kid", keyId),
                new Claim("iat", currentTime.ToString(), ClaimValueTypes.Integer64),
                new Claim("exp", (currentTime + 300).ToString(), ClaimValueTypes.Integer64)
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                SigningCredentials = credentials,
                AdditionalHeaderClaims = new Dictionary<string, object>
                {
                    { "kid", keyId },
                    { "gv-ver", "GV-JWT-V1" }
                }
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        /// <summary>
        /// Make an authenticated request to the V3 API
        /// </summary>
        public async Task<T> MakeAuthenticatedRequestAsync<T>(HttpMethod method, string endpoint, 
            object data = null, Dictionary<string, string> queryParams = null)
        {
            // Generate fresh JWT token
            var token = GenerateJWT();

            // Create request
            var request = new HttpRequestMessage(method, BuildUrl(endpoint, queryParams));
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

            // Add body if provided
            if (data != null && (method == HttpMethod.Post || method == HttpMethod.Put))
            {
                var json = JsonConvert.SerializeObject(data);
                request.Content = new StringContent(json, Encoding.UTF8, "application/json");
            }

            // Send request
            var response = await _httpClient.SendAsync(request);

            // Handle response
            var responseContent = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                return JsonConvert.DeserializeObject<T>(responseContent);
            }
            else
            {
                throw new Exception($"API Error: {response.StatusCode} - {responseContent}");
            }
        }

        /// <summary>
        /// Generate an RSA key pair for JWT signing
        /// </summary>
        /// <param name="keySize">Key size in bits (default 2048)</param>
        /// <returns>Tuple of (privateKeyPem, publicKeyPem)</returns>
        public static (string privateKey, string publicKey) GenerateRSAKeyPair(int keySize = 2048)
        {
            using var rsa = RSA.Create(keySize);
            
            // Export private key in PEM format
            var privateKey = ExportPrivateKeyPem(rsa);
            
            // Export public key in PEM format
            var publicKey = ExportPublicKeyPem(rsa);
            
            return (privateKey, publicKey);
        }

        /// <summary>
        /// Validate JWT using RSA public key
        /// </summary>
        public static bool ValidateJWT(string token, string publicKeyPem, out JwtSecurityToken validatedToken)
        {
            validatedToken = null;

            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var publicKey = LoadPublicKeyFromPem(publicKeyPem);

                var validationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new RsaSecurityKey(publicKey),
                    ValidateAudience = true,
                    ValidAudience = "groupvan",
                    ValidateIssuer = false,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero
                };

                SecurityToken validatedSecurityToken;
                tokenHandler.ValidateToken(token, validationParameters, out validatedSecurityToken);
                validatedToken = validatedSecurityToken as JwtSecurityToken;
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Load RSA private key from PEM format
        /// </summary>
        private static RSA LoadPrivateKeyFromPem(string pem)
        {
            var rsa = RSA.Create();
            rsa.ImportFromPem(pem.ToCharArray());
            return rsa;
        }

        /// <summary>
        /// Load RSA public key from PEM format
        /// </summary>
        private static RSA LoadPublicKeyFromPem(string pem)
        {
            var rsa = RSA.Create();
            rsa.ImportFromPem(pem.ToCharArray());
            return rsa;
        }

        /// <summary>
        /// Export RSA private key to PEM format
        /// </summary>
        private static string ExportPrivateKeyPem(RSA rsa)
        {
            var privateKeyBytes = rsa.ExportRSAPrivateKey();
            var sb = new StringBuilder();
            sb.AppendLine("-----BEGIN RSA PRIVATE KEY-----");
            sb.AppendLine(Convert.ToBase64String(privateKeyBytes, Base64FormattingOptions.InsertLineBreaks));
            sb.AppendLine("-----END RSA PRIVATE KEY-----");
            return sb.ToString();
        }

        /// <summary>
        /// Export RSA public key to PEM format
        /// </summary>
        private static string ExportPublicKeyPem(RSA rsa)
        {
            var publicKeyBytes = rsa.ExportSubjectPublicKeyInfo();
            var sb = new StringBuilder();
            sb.AppendLine("-----BEGIN PUBLIC KEY-----");
            sb.AppendLine(Convert.ToBase64String(publicKeyBytes, Base64FormattingOptions.InsertLineBreaks));
            sb.AppendLine("-----END PUBLIC KEY-----");
            return sb.ToString();
        }

        private string BuildUrl(string endpoint, Dictionary<string, string> queryParams)
        {
            if (queryParams == null || queryParams.Count == 0)
                return endpoint;

            var queryString = System.Web.HttpUtility.ParseQueryString(string.Empty);
            foreach (var param in queryParams)
            {
                queryString[param.Key] = param.Value;
            }

            return $"{endpoint}?{queryString}";
        }

        public void Dispose()
        {
            _privateKey?.Dispose();
            _httpClient?.Dispose();
        }

        /// <summary>
        /// Example: Get a catalog by ID
        /// </summary>
        public async Task<dynamic> GetCatalogAsync(string catalogId)
        {
            return await MakeAuthenticatedRequestAsync<dynamic>(
                HttpMethod.Get, 
                $"/catalogs/{catalogId}"
            );
        }

        /// <summary>
        /// Example: List available catalogs
        /// </summary>
        public async Task<CatalogListResponse> ListCatalogsAsync(int limit = 10, int offset = 0)
        {
            var queryParams = new Dictionary<string, string>
            {
                { "limit", limit.ToString() },
                { "offset", offset.ToString() }
            };

            return await MakeAuthenticatedRequestAsync<CatalogListResponse>(
                HttpMethod.Get, 
                "/catalogs",
                null,
                queryParams
            );
        }

        /// <summary>
        /// Example: Create a new catalog
        /// </summary>
        public async Task<dynamic> CreateCatalogAsync(object catalogData)
        {
            return await MakeAuthenticatedRequestAsync<dynamic>(
                HttpMethod.Post,
                "/catalogs",
                catalogData
            );
        }
    }

    /// <summary>
    /// Response model for catalog list
    /// </summary>
    public class CatalogListResponse
    {
        public List<Catalog> Items { get; set; }
        public int Total { get; set; }
        public int Limit { get; set; }
        public int Offset { get; set; }
    }

    /// <summary>
    /// Catalog model
    /// </summary>
    public class Catalog
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string Type { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    /// <summary>
    /// Example program demonstrating JWT authentication with RSA256
    /// </summary>
    public class Program
    {
        public static async Task Main(string[] args)
        {
            Console.WriteLine(new string('=', 60));
            Console.WriteLine("GroupVAN JWT Authentication Example for C#/.NET (RSA256)");
            Console.WriteLine(new string('=', 60));

            // Example 1: Generate RSA key pair
            Console.WriteLine("\n1. Generating RSA key pair:");

            var (privateKeyPem, publicKeyPem) = GroupVANClient.GenerateRSAKeyPair();
            
            Console.WriteLine("Private Key (keep this secret!):");
            Console.WriteLine(privateKeyPem.Substring(0, Math.Min(200, privateKeyPem.Length)) + "...");
            Console.WriteLine("\nPublic Key (share with server):");
            Console.WriteLine(publicKeyPem.Substring(0, Math.Min(200, publicKeyPem.Length)) + "...");

            // Example 2: Generate JWT with RSA256
            Console.WriteLine("\n2. Generating JWT:");

            var accessKey = new Dictionary<string, string>
            {
                { "developer_id", "dev_abc123" },
                { "key_id", "key_xyz789" },
                { "private_key", privateKeyPem }  // RSA private key instead of shared secret
            };

            var token = GroupVANClient.GenerateJWT(accessKey);
            Console.WriteLine($"Generated Token: {token.Substring(0, Math.Min(50, token.Length))}...");

            // Decode token to show claims (for debugging)
            var handler = new JwtSecurityTokenHandler();
            var jsonToken = handler.ReadJwtToken(token);
            Console.WriteLine("\nToken Claims:");
            foreach (var claim in jsonToken.Claims)
            {
                Console.WriteLine($"  {claim.Type}: {claim.Value}");
            }
            
            Console.WriteLine("\nToken Header:");
            Console.WriteLine($"  Algorithm: {jsonToken.Header.Alg}");
            Console.WriteLine($"  Key ID: {jsonToken.Header.Kid}");
            if (jsonToken.Header.TryGetValue("gv-ver", out var gvVer))
            {
                Console.WriteLine($"  GV Version: {gvVer}");
            }

            // Example 3: Verify token with public key
            Console.WriteLine("\n3. Verifying token with public key:");
            JwtSecurityToken validatedToken;
            bool isValid = GroupVANClient.ValidateJWT(
                token,
                publicKeyPem,
                out validatedToken
            );
            Console.WriteLine($"✓ Token is valid: {isValid}");
            if (isValid)
            {
                Console.WriteLine($"Token expires at: {validatedToken.ValidTo}");
            }

            // Example 4: Using the client class
            Console.WriteLine("\n4. Using GroupVAN Client Class:");

            using (var client = new GroupVANClient(
                "your_developer_id",
                "your_key_id",
                privateKeyPem,  // Use RSA private key
                "http://localhost:5000/v3")) // Use your actual API URL
            {
                try
                {
                    // Generate a token
                    var clientToken = client.GenerateJWT();
                    Console.WriteLine($"\nClient Token: {clientToken.Substring(0, Math.Min(50, clientToken.Length))}...");

                    // Example API calls (uncomment to test with real API)
                    /*
                    Console.WriteLine("\nListing catalogs...");
                    var catalogs = await client.ListCatalogsAsync(5);
                    Console.WriteLine($"Found {catalogs.Items?.Count ?? 0} catalogs");

                    if (catalogs.Items?.Count > 0)
                    {
                        var catalogId = catalogs.Items[0].Id;
                        Console.WriteLine($"\nGetting catalog {catalogId}...");
                        var catalog = await client.GetCatalogAsync(catalogId);
                        Console.WriteLine($"Catalog name: {catalog.name}");
                    }

                    Console.WriteLine("\nCreating a new catalog...");
                    var newCatalog = await client.CreateCatalogAsync(new
                    {
                        name = "Test Catalog",
                        description = "Created from C# client with RSA256",
                        type = "products"
                    });
                    Console.WriteLine($"Created catalog with ID: {newCatalog.id}");
                    */
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error: {ex.Message}");
                }
            }

            // Example 5: Important notes
            Console.WriteLine("\n" + new string('=', 60));
            Console.WriteLine("Important Notes:");
            Console.WriteLine("- Server only needs your PUBLIC key to verify tokens");
            Console.WriteLine("- Keep your PRIVATE key secure and never share it");
            Console.WriteLine("- Use RS256 algorithm for enhanced security");
            Console.WriteLine("- Tokens are now signed with asymmetric cryptography");
            Console.WriteLine(new string('=', 60));

            Console.WriteLine("\nPress any key to exit...");
            Console.ReadKey();
        }
    }
}