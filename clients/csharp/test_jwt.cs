using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;
using GroupVAN.Auth;

class TestJWT
{
    static void Main()
    {
        var (privateKeyPem, _) = GroupVANClient.GenerateRSAKeyPair();
        var client = new GroupVANClient("test_dev_123", "test_key_456", privateKeyPem);
        var token = client.GenerateJWT();
        
        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(token);
        
        Console.WriteLine("Headers:");
        foreach (var header in jwt.Header)
        {
            Console.WriteLine($"  {header.Key}: {header.Value}");
        }
        
        Console.WriteLine("\nClaims:");
        foreach (var claim in jwt.Claims)
        {
            Console.WriteLine($"  {claim.Type}: {claim.Value}");
        }
    }
}
