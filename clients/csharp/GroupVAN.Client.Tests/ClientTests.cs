using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;
using Xunit;
using GroupVAN.Auth;

namespace GroupVAN.Client.Tests
{
    public class ClientTests
    {
        private readonly RSA _rsa;
        private readonly RsaSecurityKey _privateKey;
        private readonly RsaSecurityKey _publicKey;

        public ClientTests()
        {
            _rsa = RSA.Create(2048);
            _privateKey = new RsaSecurityKey(_rsa);
            _publicKey = new RsaSecurityKey(_rsa.ExportParameters(false));
        }

        [Fact]
        public void GenerateRSAKeyPair_ShouldReturnValidKeys()
        {
            // Arrange & Act
            var (privateKeyPem, publicKeyPem) = GroupVANClient.GenerateRSAKeyPair();

            // Assert
            Assert.NotNull(privateKeyPem);
            Assert.NotNull(publicKeyPem);
            Assert.Contains("BEGIN PRIVATE KEY", privateKeyPem);
            Assert.Contains("END PRIVATE KEY", privateKeyPem);
            Assert.Contains("BEGIN PUBLIC KEY", publicKeyPem);
            Assert.Contains("END PUBLIC KEY", publicKeyPem);
        }

        [Fact]
        public void GenerateJWT_ShouldReturnValidToken()
        {
            // Arrange
            var (privateKeyPem, _) = GroupVANClient.GenerateRSAKeyPair();
            var client = new GroupVANClient("test_dev_123", "test_key_456", privateKeyPem);

            // Act
            var token = client.GenerateJWT();

            // Assert
            Assert.NotNull(token);
            Assert.NotEmpty(token);

            // Verify token structure (3 parts)
            var parts = token.Split('.');
            Assert.Equal(3, parts.Length);
        }

        [Fact]
        public void GenerateJWT_ShouldIncludeCorrectClaims()
        {
            // Arrange
            var (privateKeyPem, _) = GroupVANClient.GenerateRSAKeyPair();
            var client = new GroupVANClient("test_dev_123", "test_key_456", privateKeyPem);

            // Act
            var token = client.GenerateJWT();
            var handler = new JwtSecurityTokenHandler();
            var jwt = handler.ReadJwtToken(token);

            // Assert
            Assert.Equal("groupvan", jwt.Audiences.First());
            Assert.Equal("test_dev_123", jwt.Issuer);
            Assert.Contains(jwt.Claims, c => c.Type == "kid" && c.Value == "test_key_456");
        }

        [Fact]
        public void GenerateJWT_ShouldSetCorrectHeader()
        {
            // Arrange
            var (privateKeyPem, _) = GroupVANClient.GenerateRSAKeyPair();
            var client = new GroupVANClient("test_dev_123", "test_key_456", privateKeyPem);

            // Act
            var token = client.GenerateJWT();
            var handler = new JwtSecurityTokenHandler();
            var jwt = handler.ReadJwtToken(token);

            // Assert
            Assert.Equal("RS256", jwt.Header.Alg);
            Assert.Equal("test_key_456", jwt.Header.Kid);
            Assert.Equal("GV-JWT-V1", jwt.Header["gv-ver"]);
        }

        [Fact]
        public void VerifyJWT_WithCorrectPublicKey_ShouldSucceed()
        {
            // Arrange
            var (privateKeyPem, publicKeyPem) = GroupVANClient.GenerateRSAKeyPair();
            var client = new GroupVANClient("test_dev_123", "test_key_456", privateKeyPem);
            var token = client.GenerateJWT();

            // Act & Assert (should not throw)
            var rsa = RSA.Create();
            rsa.ImportFromPem(publicKeyPem);
            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new RsaSecurityKey(rsa),
                ValidateAudience = true,
                ValidAudience = "groupvan",
                ValidateIssuer = true,
                ValidIssuer = "test_dev_123",
                ClockSkew = TimeSpan.Zero
            };

            var handler = new JwtSecurityTokenHandler();
            var principal = handler.ValidateToken(token, validationParameters, out _);

            Assert.NotNull(principal);
        }

        [Fact]
        public void VerifyJWT_WithWrongPublicKey_ShouldFail()
        {
            // Arrange
            var (privateKeyPem, _) = GroupVANClient.GenerateRSAKeyPair();
            var (_, wrongPublicKeyPem) = GroupVANClient.GenerateRSAKeyPair();
            var client = new GroupVANClient("test_dev_123", "test_key_456", privateKeyPem);
            var token = client.GenerateJWT();

            // Act & Assert
            var rsa = RSA.Create();
            rsa.ImportFromPem(wrongPublicKeyPem);
            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new RsaSecurityKey(rsa),
                ValidateAudience = true,
                ValidAudience = "groupvan",
                ValidateIssuer = true,
                ValidIssuer = "test_dev_123",
                ClockSkew = TimeSpan.Zero
            };

            var handler = new JwtSecurityTokenHandler();
            Assert.Throws<SecurityTokenSignatureKeyNotFoundException>(() =>
                handler.ValidateToken(token, validationParameters, out _));
        }

        [Fact]
        public void GenerateJWT_WithCustomExpiration_ShouldSetCorrectExpiry()
        {
            // Arrange
            var (privateKeyPem, _) = GroupVANClient.GenerateRSAKeyPair();
            var client = new GroupVANClient("test_dev_123", "test_key_456", privateKeyPem);

            // Act
            var token = client.GenerateJWT(600); // 10 minutes
            var handler = new JwtSecurityTokenHandler();
            var jwt = handler.ReadJwtToken(token);

            // Assert
            var expectedExpiry = DateTime.UtcNow.AddSeconds(600);
            Assert.InRange(jwt.ValidTo, expectedExpiry.AddSeconds(-10), expectedExpiry.AddSeconds(10));
        }

        [Fact]
        public void Client_ShouldHaveRequiredMethods()
        {
            // Arrange
            var (privateKeyPem, _) = GroupVANClient.GenerateRSAKeyPair();
            var client = new GroupVANClient("test_dev_123", "test_key_456", privateKeyPem);

            // Assert
            Assert.NotNull(client.GetType().GetMethod("GenerateJWT"));
            Assert.NotNull(client.GetType().GetMethod("MakeAuthenticatedRequestAsync"));
            Assert.NotNull(client.GetType().GetMethod("GetCatalogAsync"));
            Assert.NotNull(client.GetType().GetMethod("ListCatalogsAsync"));
        }
    }
}