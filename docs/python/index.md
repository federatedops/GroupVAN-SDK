---
layout: default
title: Python
nav_order: 4
has_children: true
---

# Python Client Library
{: .no_toc }

Complete documentation for the GroupVAN Python client library.
{: .fs-6 .fw-300 }

---

## Installation

### Requirements
- Python 3.8 or higher
- pip package manager

### Install from PyPI

```bash
pip install groupvan-client
```

### Install from Source

```bash
git clone https://github.com/federatedops/groupvan-api-client.git
cd groupvan-api-client/clients/python
pip install -e .
```

### Dependencies

The client automatically installs these dependencies:
- `PyJWT>=2.8.0` - JWT token generation
- `cryptography>=41.0.0` - RSA key handling
- `requests>=2.31.0` - HTTP client (optional)

## Quick Example

```python
from groupvan_client import GroupVANClient

# Initialize client
client = GroupVANClient(
    developer_id="DEV123",
    key_id="KEY001",
    private_key_path="/path/to/private_key.pem"
)

# Generate JWT token
token = client.generate_token()

# Make API call
response = client.api_call(
    method="GET",
    endpoint="/api/v3/users",
    token=token
)

print(response.json())
```

## Configuration

### Using Environment Variables

```python
import os
from groupvan_client import GroupVANClient

client = GroupVANClient.from_env()
# Looks for:
# - GROUPVAN_DEVELOPER_ID
# - GROUPVAN_KEY_ID  
# - GROUPVAN_PRIVATE_KEY_PATH or GROUPVAN_PRIVATE_KEY
```

### Using Configuration File

```python
# config.json
{
    "developer_id": "DEV123",
    "key_id": "KEY001",
    "private_key_path": "/path/to/private_key.pem"
}

# Load configuration
client = GroupVANClient.from_config("config.json")
```

### Direct Initialization

```python
# With file path
client = GroupVANClient(
    developer_id="DEV123",
    key_id="KEY001", 
    private_key_path="/path/to/private_key.pem"
)

# With key content
with open("private_key.pem", "r") as f:
    private_key = f.read()

client = GroupVANClient(
    developer_id="DEV123",
    key_id="KEY001",
    private_key=private_key
)
```

## API Reference

### GroupVANClient Class

#### Constructor Parameters

| Parameter | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `developer_id` | str | Yes | Your GroupVAN developer ID |
| `key_id` | str | Yes | Your key identifier |
| `private_key_path` | str | No* | Path to private key file |
| `private_key` | str | No* | Private key content |
| `base_url` | str | No | API base URL (default: https://api.groupvan.com) |
| `timeout` | int | No | Request timeout in seconds (default: 30) |

*One of `private_key_path` or `private_key` is required

#### Methods

##### generate_token()
Generate a JWT token for API authentication.

```python
def generate_token(
    self,
    expiration_minutes: int = 5,
    additional_claims: dict = None
) -> str:
```

**Parameters:**
- `expiration_minutes` (int): Token validity period (default: 5)
- `additional_claims` (dict): Additional JWT claims

**Returns:**
- `str`: JWT token

**Example:**
```python
# Default 5-minute expiration
token = client.generate_token()

# Custom expiration
token = client.generate_token(expiration_minutes=10)

# With additional claims
token = client.generate_token(
    additional_claims={"scope": "read:users"}
)
```

##### api_call()
Make an authenticated API call.

```python
def api_call(
    self,
    method: str,
    endpoint: str,
    token: str = None,
    data: dict = None,
    params: dict = None,
    headers: dict = None
) -> requests.Response:
```

**Parameters:**
- `method` (str): HTTP method (GET, POST, PUT, DELETE)
- `endpoint` (str): API endpoint path
- `token` (str): JWT token (auto-generated if not provided)
- `data` (dict): Request body for POST/PUT
- `params` (dict): Query parameters
- `headers` (dict): Additional headers

**Returns:**
- `requests.Response`: HTTP response object

**Example:**
```python
# GET request
response = client.api_call("GET", "/api/v3/users")

# POST request with data
response = client.api_call(
    method="POST",
    endpoint="/api/v3/users",
    data={"name": "John Doe", "email": "john@example.com"}
)

# With query parameters
response = client.api_call(
    method="GET",
    endpoint="/api/v3/users",
    params={"page": 1, "limit": 10}
)
```

### Utility Functions

#### generate_rsa_key_pair()
Generate a new RSA key pair.

```python
from groupvan_client import generate_rsa_key_pair

private_key, public_key = generate_rsa_key_pair(
    key_size=2048,
    save_to_files=True,
    private_key_path="private_key.pem",
    public_key_path="public_key.pem"
)
```

**Parameters:**
- `key_size` (int): RSA key size in bits (default: 2048)
- `save_to_files` (bool): Save keys to files (default: True)
- `private_key_path` (str): Private key file path
- `public_key_path` (str): Public key file path

**Returns:**
- `tuple[str, str]`: (private_key, public_key) as PEM strings

#### load_private_key()
Load a private key from file or string.

```python
from groupvan_client import load_private_key

# From file
key = load_private_key(file_path="private_key.pem")

# From string
key = load_private_key(key_string=private_key_pem)
```

## Error Handling

### Exception Types

```python
from groupvan_client.exceptions import (
    GroupVANError,          # Base exception
    AuthenticationError,    # Authentication failures
    ConfigurationError,     # Invalid configuration
    TokenGenerationError,   # Token generation issues
    APIError               # API call failures
)
```

### Error Handling Example

```python
from groupvan_client import GroupVANClient
from groupvan_client.exceptions import (
    AuthenticationError,
    TokenGenerationError,
    APIError
)

try:
    client = GroupVANClient(
        developer_id="DEV123",
        key_id="KEY001",
        private_key_path="private_key.pem"
    )
    
    token = client.generate_token()
    response = client.api_call("GET", "/api/v3/users", token)
    
except ConfigurationError as e:
    print(f"Configuration error: {e}")
    # Check your configuration settings
    
except TokenGenerationError as e:
    print(f"Failed to generate token: {e}")
    # Check private key and credentials
    
except AuthenticationError as e:
    print(f"Authentication failed: {e}")
    # Token may be expired or invalid
    
except APIError as e:
    print(f"API call failed: {e}")
    print(f"Status code: {e.status_code}")
    print(f"Response: {e.response}")
    
except GroupVANError as e:
    print(f"Unexpected error: {e}")
```

## Advanced Usage

### Custom Token Claims

```python
# Add custom claims to JWT
token = client.generate_token(
    additional_claims={
        "scope": "read:users write:users",
        "tenant_id": "TENANT123",
        "ip_address": "192.168.1.1"
    }
)
```

### Retry Logic

```python
import time
from typing import Optional

def api_call_with_retry(
    client: GroupVANClient,
    method: str,
    endpoint: str,
    max_retries: int = 3,
    backoff_factor: float = 1.0
) -> Optional[requests.Response]:
    """Make API call with exponential backoff retry"""
    
    for attempt in range(max_retries):
        try:
            return client.api_call(method, endpoint)
        except APIError as e:
            if e.status_code >= 500 and attempt < max_retries - 1:
                wait_time = backoff_factor * (2 ** attempt)
                print(f"Retry {attempt + 1}/{max_retries} after {wait_time}s")
                time.sleep(wait_time)
            else:
                raise
    
    return None
```

### Connection Pooling

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Create session with connection pooling
session = requests.Session()

# Configure retry strategy
retry_strategy = Retry(
    total=3,
    status_forcelist=[429, 500, 502, 503, 504],
    allowed_methods=["HEAD", "GET", "OPTIONS"],
    backoff_factor=1
)

adapter = HTTPAdapter(
    max_retries=retry_strategy,
    pool_connections=10,
    pool_maxsize=10
)

session.mount("https://", adapter)

# Use session with client
client = GroupVANClient(
    developer_id="DEV123",
    key_id="KEY001",
    private_key_path="private_key.pem",
    session=session  # Pass custom session
)
```

### Async Support

```python
import asyncio
import aiohttp
from groupvan_client import GroupVANClient

async def async_api_call(client: GroupVANClient, endpoint: str):
    """Async API call using aiohttp"""
    token = client.generate_token()
    
    async with aiohttp.ClientSession() as session:
        headers = {"Authorization": f"Bearer {token}"}
        async with session.get(
            f"{client.base_url}{endpoint}",
            headers=headers
        ) as response:
            return await response.json()

# Run async
async def main():
    client = GroupVANClient(
        developer_id="DEV123",
        key_id="KEY001",
        private_key_path="private_key.pem"
    )
    
    result = await async_api_call(client, "/api/v3/users")
    print(result)

asyncio.run(main())
```

## Testing

### Unit Tests

```python
import unittest
from unittest.mock import Mock, patch
from groupvan_client import GroupVANClient

class TestGroupVANClient(unittest.TestCase):
    def setUp(self):
        self.client = GroupVANClient(
            developer_id="TEST_DEV",
            key_id="TEST_KEY",
            private_key=TEST_PRIVATE_KEY
        )
    
    def test_generate_token(self):
        token = self.client.generate_token()
        self.assertIsInstance(token, str)
        self.assertTrue(token.startswith("eyJ"))
    
    @patch('requests.get')
    def test_api_call(self, mock_get):
        mock_get.return_value.json.return_value = {"status": "ok"}
        
        response = self.client.api_call("GET", "/test")
        
        self.assertEqual(response.json(), {"status": "ok"})
        mock_get.assert_called_once()
```

### Integration Tests

```python
import pytest
from groupvan_client import GroupVANClient

@pytest.fixture
def client():
    return GroupVANClient(
        developer_id=os.environ["TEST_DEVELOPER_ID"],
        key_id=os.environ["TEST_KEY_ID"],
        private_key_path=os.environ["TEST_PRIVATE_KEY_PATH"]
    )

def test_real_api_call(client):
    """Test against real API"""
    response = client.api_call("GET", "/api/v3/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|:------|:------|:---------|
| `FileNotFoundError` | Private key file not found | Check file path and permissions |
| `Invalid key format` | Corrupted or wrong key format | Regenerate RSA key pair |
| `Token expired` | Token lifetime exceeded | Generate new token before each API call |
| `401 Unauthorized` | Invalid credentials | Verify developer_id and key_id |
| `Connection timeout` | Network issues | Check network connectivity and firewall |

### Debug Logging

```python
import logging

# Enable debug logging
logging.basicConfig(level=logging.DEBUG)

# Or configure specific logger
logger = logging.getLogger('groupvan_client')
logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler()
handler.setFormatter(
    logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
)
logger.addHandler(handler)

# Client will now log debug information
client = GroupVANClient(...)
```

## Migration Guide

### From Version 0.x to 1.0

```python
# Old (v0.x)
from groupvan import Client
client = Client(dev_id="DEV123", private_key="key.pem")
token = client.get_token()

# New (v1.0+)
from groupvan_client import GroupVANClient
client = GroupVANClient(
    developer_id="DEV123",
    key_id="KEY001",
    private_key_path="key.pem"
)
token = client.generate_token()
```

## Resources

- [Source Code](https://github.com/federatedops/groupvan-api-client/tree/main/clients/python)
- [PyPI Package](https://pypi.org/project/groupvan-client)
- [Example Scripts](https://github.com/federatedops/groupvan-api-client/tree/main/examples/python)
- [Issue Tracker](https://github.com/federatedops/groupvan-api-client/issues)