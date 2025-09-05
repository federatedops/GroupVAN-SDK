# GroupVAN Python Client Library

Python client for authenticating with GroupVAN V3 APIs using JWT tokens with RSA256.

## Installation

```bash
pip install pyjwt cryptography requests
```

Or using requirements.txt:
```bash
pip install -r requirements.txt
```

## Quick Start

```python
from client import GroupVANClient, generate_rsa_key_pair

# Generate RSA key pair
private_key, public_key = generate_rsa_key_pair()

# Initialize client
client = GroupVANClient(
    developer_id="your_developer_id",
    key_id="your_key_id", 
    private_key_pem=private_key
)

# Generate JWT token
token = client.generate_jwt()

# Make API calls
catalogs = client.list_catalogs(limit=10)
catalog = client.get_catalog("catalog_123")
```

## RSA Key Management

### Generate New Key Pair

```python
from client import generate_rsa_key_pair

# Generate 2048-bit RSA key pair
private_key, public_key = generate_rsa_key_pair(key_size=2048)

# Save keys to files
with open("private_key.pem", "w") as f:
    f.write(private_key)

with open("public_key.pem", "w") as f:
    f.write(public_key)

print("Public key to share with GroupVAN:")
print(public_key)
```

### Load Existing Keys

```python
# Load private key from file
with open("private_key.pem", "r") as f:
    private_key = f.read()

client = GroupVANClient(
    developer_id="your_developer_id",
    key_id="your_key_id",
    private_key_pem=private_key
)
```

## JWT Token Generation

Tokens are automatically generated with these claims:

```python
{
    "aud": "groupvan",
    "iss": "your_developer_id",
    "kid": "your_key_id",
    "exp": current_time + 300,  # 5 minutes
    "iat": current_time
}
```

With header:
```python
{
    "alg": "RS256",
    "typ": "JWT",
    "kid": "your_key_id",
    "gv-ver": "GV-JWT-V1"
}
```

Custom expiration:
```python
# Generate token with 10-minute expiration
token = client.generate_jwt(expires_in=600)
```

## API Methods

### List Catalogs
```python
catalogs = client.list_catalogs(limit=10, offset=0)
print(f"Found {len(catalogs.get('items', []))} catalogs")
```

### Get Catalog
```python
catalog = client.get_catalog("catalog_123")
print(f"Catalog name: {catalog.get('name')}")
```

### Custom Requests
```python
response = client.make_authenticated_request(
    method="POST",
    endpoint="/catalogs",
    data={
        "name": "New Catalog",
        "type": "products"
    }
)
```

## Token Verification

Verify tokens using the public key (server-side operation):

```python
import jwt

# Verify token with public key
try:
    payload = jwt.decode(
        token,
        public_key,
        algorithms=["RS256"],
        audience="groupvan"
    )
    print("Token is valid:", payload)
except jwt.InvalidTokenError as e:
    print("Token verification failed:", e)
```

## Environment Variables

```bash
export GROUPVAN_DEVELOPER_ID="your_developer_id"
export GROUPVAN_KEY_ID="your_key_id"
export GROUPVAN_PRIVATE_KEY_PATH="/path/to/private_key.pem"
export GROUPVAN_API_URL="https://api.groupvan.com/v3"
```

Load from environment:
```python
import os

# Load private key from file
with open(os.getenv("GROUPVAN_PRIVATE_KEY_PATH"), "r") as f:
    private_key = f.read()

client = GroupVANClient(
    developer_id=os.getenv("GROUPVAN_DEVELOPER_ID"),
    key_id=os.getenv("GROUPVAN_KEY_ID"),
    private_key_pem=private_key
)
```

## Error Handling

```python
from client import GroupVANClient

try:
    catalog = client.get_catalog("catalog_123")
except Exception as e:
    if "401" in str(e):
        print("Authentication failed - check your credentials")
    elif "404" in str(e):
        print("Catalog not found")
    else:
        print(f"Error: {e}")
```

## Complete Example

```python
#!/usr/bin/env python3
from client import GroupVANClient, generate_rsa_key_pair
import json

def main():
    # Generate RSA keys
    private_key, public_key = generate_rsa_key_pair()
    
    print("=" * 60)
    print("GroupVAN JWT Authentication Example (RSA256)")
    print("=" * 60)
    
    print("\nPublic Key (share with GroupVAN):")
    print(public_key[:200] + "...")
    
    # Initialize client
    client = GroupVANClient(
        developer_id="dev_abc123",
        key_id="key_xyz789",
        private_key_pem=private_key
    )
    
    # Generate token
    token = client.generate_jwt()
    print(f"\nGenerated Token: {token[:50]}...")
    
    # Decode token to show claims
    import jwt
    decoded = jwt.decode(token, options={"verify_signature": False})
    print(f"\nToken claims: {json.dumps(decoded, indent=2)}")
    
    # Verify token with public key
    try:
        verified = jwt.decode(token, public_key, algorithms=["RS256"], audience="groupvan")
        print("\n✓ Token verified successfully!")
    except jwt.InvalidTokenError as e:
        print(f"\n✗ Token verification failed: {e}")
    
    # Example API calls (uncomment to test)
    """
    try:
        catalogs = client.list_catalogs(limit=5)
        print(f"\nFound {len(catalogs.get('items', []))} catalogs")
        
        if catalogs.get('items'):
            catalog_id = catalogs['items'][0]['id']
            catalog = client.get_catalog(catalog_id)
            print(f"First catalog: {catalog.get('name')}")
    
    except Exception as e:
        print(f"API Error: {e}")
    """

if __name__ == "__main__":
    main()
```

## Running the Example

```bash
python client.py
```

## API Reference

### Class: `GroupVANClient`

#### Constructor
```python
GroupVANClient(developer_id: str, key_id: str, private_key_pem: str)
```
- `developer_id`: Your developer ID
- `key_id`: Your key ID  
- `private_key_pem`: RSA private key in PEM format

#### Methods

- `generate_jwt(expires_in: int = 300) -> str`: Generate JWT token
- `make_authenticated_request(method, endpoint, data, params) -> dict`: Make API request
- `get_catalog(catalog_id: str) -> dict`: Get catalog by ID
- `list_catalogs(limit: int, offset: int) -> dict`: List catalogs

### Function: `generate_rsa_key_pair`

```python
generate_rsa_key_pair(key_size: int = 2048) -> tuple[str, str]
```
Returns tuple of (private_key_pem, public_key_pem)

## Dependencies

- `pyjwt>=2.8.0` - JWT token generation and validation
- `cryptography>=41.0.0` - RSA key generation
- `requests>=2.31.0` - HTTP client

## Security Notes

1. **Private Key Security**: Never commit private keys to version control
2. **Key Storage**: Use secure key management systems in production
3. **Token Expiration**: Keep tokens short-lived (5-15 minutes)
4. **HTTPS Only**: Always use HTTPS in production
5. **Key Rotation**: Implement regular key rotation

## Troubleshooting

### ImportError: No module named 'cryptography'
```bash
pip install cryptography
```

### JWT decode error
- Ensure public key matches private key
- Verify token hasn't expired
- Check system time is synchronized

### Connection errors
- Verify API URL is correct
- Check network connectivity
- Ensure firewall allows HTTPS traffic

## Testing

```bash
# Run example client
python client.py

# Run with custom credentials
GROUPVAN_DEVELOPER_ID=dev_123 python client.py
```

## License

MIT License - See LICENSE file for details

## Support

For issues or questions, contact the GroupVAN API team at api@groupvan.com