---
layout: default
title: Quick Start
nav_order: 2
---

# Quick Start Guide
{: .no_toc }

Get up and running with GroupVAN API authentication in minutes.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Prerequisites

<div class="callout callout-info" markdown="1">
<div class="callout-title">Before You Begin</div>

Ensure you have:
- A GroupVAN developer account
- Your preferred programming language environment set up
- Basic understanding of JWT and RSA cryptography concepts
</div>

## Generating RSA Keys

Each client library includes built-in utilities to generate RSA key pairs. Choose your preferred language:

### Python
```bash
python -c "from groupvan_client import generate_rsa_key_pair; generate_rsa_key_pair()"
```

### Node.js
```bash
npx @groupvan/client keygen
```

### PHP
```bash
php -r "require 'vendor/autoload.php'; GroupVAN\Client::generateKeyPair();"
```

### C#/.NET
```bash
dotnet run --project GroupVAN.Client.KeyGen
```

<div class="callout callout-warning" markdown="1">
<div class="callout-title">Security Warning</div>

This will generate two files:
- `private_key.pem` - **Keep this secret!** Never share or commit to version control
- `public_key.pem` - Share this with your GroupVAN Integration Specialist

Never commit private keys to version control or share them with anyone!
</div>

## Registering Your Public Key

1. Contact your GroupVAN Integration Specialist
2. Provide your:
   - Developer ID
   - Public key (contents of `public_key.pem`)
   - Key ID (for key rotation management)
3. Wait for confirmation that your key has been registered

## Installation

### Python

```bash
# Using pip
pip install groupvan-client

# Using requirements.txt
echo "groupvan-client>=1.0.0" >> requirements.txt
pip install -r requirements.txt
```

### Node.js

```bash
# Using npm
npm install @groupvan/client

# Using yarn
yarn add @groupvan/client

# Add to package.json
npm install --save @groupvan/client
```

### PHP

```bash
# Using composer
composer require groupvan/client

# Add to composer.json
{
    "require": {
        "groupvan/client": "^1.0"
    }
}
```

### C#/.NET

```bash
# Using .NET CLI
dotnet add package GroupVAN.Client

# Using Package Manager
Install-Package GroupVAN.Client

# Add to .csproj
<PackageReference Include="GroupVAN.Client" Version="1.0.0" />
```

## Authentication

### Basic Token Generation

#### Python
```python
from groupvan_client import GroupVANClient

# Initialize client
client = GroupVANClient(
    developer_id="DEV123",
    key_id="KEY001",
    private_key_path="path/to/private_key.pem"
)

# Generate token
token = client.generate_token()
print(f"Token: {token}")
```

#### Node.js
```javascript
const { GroupVANClient } = require('@groupvan/client');

// Initialize client
const client = new GroupVANClient({
    developerId: 'DEV123',
    keyId: 'KEY001',
    privateKeyPath: 'path/to/private_key.pem'
});

// Generate token
const token = client.generateToken();
console.log(`Token: ${token}`);
```

#### PHP
```php
<?php
use GroupVAN\Client;

// Initialize client
$client = new Client([
    'developer_id' => 'DEV123',
    'key_id' => 'KEY001',
    'private_key_path' => 'path/to/private_key.pem'
]);

// Generate token
$token = $client->generateToken();
echo "Token: " . $token;
```

#### C#/.NET
```csharp
using GroupVAN.Client;

// Initialize client
var client = new GroupVANClient(
    developerId: "DEV123",
    keyId: "KEY001",
    privateKeyPath: "path/to/private_key.pem"
);

// Generate token
var token = client.GenerateToken();
Console.WriteLine($"Token: {token}");
```

## Making API Calls

Once you have a token, use it in the Authorization header:

### Using Built-in Methods

#### Python
```python
# Make authenticated API call
response = client.api_call(
    method="GET",
    endpoint="/api/v3/users",
    token=token
)
print(response.json())
```

#### Node.js
```javascript
// Make authenticated API call
const response = await client.apiCall({
    method: 'GET',
    endpoint: '/api/v3/users',
    token: token
});
console.log(response.data);
```

### Manual HTTP Requests

```bash
# Using curl
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
     https://api.groupvan.com/v3/users

# Using HTTPie
http GET https://api.groupvan.com/v3/users \
     "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Environment Variables

For production deployments, use environment variables to store sensitive configuration:

### Setting Environment Variables

```bash
# Linux/macOS
export GROUPVAN_DEVELOPER_ID="DEV123"
export GROUPVAN_KEY_ID="KEY001"
export GROUPVAN_PRIVATE_KEY_PATH="/secure/path/private_key.pem"

# Windows
set GROUPVAN_DEVELOPER_ID=DEV123
set GROUPVAN_KEY_ID=KEY001
set GROUPVAN_PRIVATE_KEY_PATH=C:\secure\path\private_key.pem
```

### Using Environment Variables

#### Python
```python
import os
from groupvan_client import GroupVANClient

client = GroupVANClient(
    developer_id=os.environ['GROUPVAN_DEVELOPER_ID'],
    key_id=os.environ['GROUPVAN_KEY_ID'],
    private_key_path=os.environ['GROUPVAN_PRIVATE_KEY_PATH']
)
```

#### Node.js
```javascript
const { GroupVANClient } = require('@groupvan/client');

const client = new GroupVANClient({
    developerId: process.env.GROUPVAN_DEVELOPER_ID,
    keyId: process.env.GROUPVAN_KEY_ID,
    privateKeyPath: process.env.GROUPVAN_PRIVATE_KEY_PATH
});
```

## Error Handling

All client libraries provide comprehensive error handling:

### Python
```python
try:
    token = client.generate_token()
    response = client.api_call("GET", "/api/v3/users", token)
except AuthenticationError as e:
    print(f"Authentication failed: {e}")
except APIError as e:
    print(f"API call failed: {e}")
```

### Node.js
```javascript
try {
    const token = client.generateToken();
    const response = await client.apiCall('GET', '/api/v3/users', token);
} catch (error) {
    if (error.name === 'AuthenticationError') {
        console.error('Authentication failed:', error.message);
    } else if (error.name === 'APIError') {
        console.error('API call failed:', error.message);
    }
}
```

## Next Steps

- 📚 Explore language-specific documentation:
  - [Python Documentation](python/)
  - [Node.js Documentation](nodejs/)
  - [PHP Documentation](php/)
  - [C# Documentation](csharp/)
- 🔒 Review [Security Best Practices](security)
- 🧪 Check out [Example Applications](https://github.com/federatedops/GroupVAN-SDK/tree/main/examples)
- 📖 Read the full [API Documentation](https://api.groupvan.com/docs)

## Getting Help

If you encounter any issues:

1. Check the [Troubleshooting Guide](troubleshooting)
2. Search [existing issues](https://github.com/federatedops/GroupVAN-SDK/issues)
3. Contact your GroupVAN Integration Specialist
4. [Open a new issue](https://github.com/federatedops/GroupVAN-SDK/issues/new) on GitHub