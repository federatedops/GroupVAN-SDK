---
layout: home
title: Home
nav_order: 1
description: "Official client libraries for authenticating with GroupVAN V3 APIs using JWT tokens with RSA256 asymmetric cryptography."
permalink: /
---

<div class="hero" markdown="1">

# GroupVAN API Client Libraries
{: .fs-9 }

Secure, easy-to-use client libraries for GroupVAN V3 API authentication.
{: .fs-6 .fw-300 .hero-subtitle }

[![Python CI](https://github.com/federatedops/groupvan-api-client/actions/workflows/python.yml/badge.svg)](https://github.com/federatedops/groupvan-api-client/actions/workflows/python.yml)
[![Node.js CI](https://github.com/federatedops/groupvan-api-client/actions/workflows/nodejs.yml/badge.svg)](https://github.com/federatedops/groupvan-api-client/actions/workflows/nodejs.yml)
[![PHP CI](https://github.com/federatedops/groupvan-api-client/actions/workflows/php.yml/badge.svg)](https://github.com/federatedops/groupvan-api-client/actions/workflows/php.yml)
[![.NET CI](https://github.com/federatedops/groupvan-api-client/actions/workflows/dotnet.yml/badge.svg)](https://github.com/federatedops/groupvan-api-client/actions/workflows/dotnet.yml)
[![Documentation](https://github.com/federatedops/groupvan-api-client/actions/workflows/docs.yml/badge.svg)](https://github.com/federatedops/groupvan-api-client/actions/workflows/docs.yml)
{: .text-center }

<div class="hero-buttons" markdown="1">

[Get Started](quickstart){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/federatedops/groupvan-api-client){: .btn .fs-5 .mb-4 .mb-md-0 }

</div>
</div>

---

## Overview

The GroupVAN API Client libraries provide a secure and standardized way to authenticate with GroupVAN's V3 APIs across multiple programming languages. All libraries implement the same authentication pattern using RSA256 (RS256) algorithm for enhanced security through asymmetric cryptography.

## Available Libraries

<div class="code-example" markdown="1">

| Language | Package | Version | Documentation |
|:---------|:--------|:--------|:--------------|
| **Python** | `groupvan-client` | ![PyPI](https://img.shields.io/pypi/v/groupvan-client) | [Python Docs](python/) |
| **Node.js** | `@groupvan/client` | ![npm](https://img.shields.io/npm/v/@groupvan/client) | [Node.js Docs](nodejs/) |
| **PHP** | `groupvan/client` | ![Packagist](https://img.shields.io/packagist/v/groupvan/client) | [PHP Docs](php/) |
| **C#/.NET** | `GroupVAN.Client` | ![NuGet](https://img.shields.io/nuget/v/GroupVAN.Client) | [C# Docs](csharp/) |

</div>

## Quick Installation

### Python
```bash
pip install groupvan-client
```

### Node.js
```bash
npm install @groupvan/client
```

### PHP
```bash
composer require groupvan/client
```

### C#/.NET
```bash
dotnet add package GroupVAN.Client
```

## Key Features

<div class="feature-card" markdown="1">
<div class="feature-icon">🔐</div>

### RSA256 Asymmetric Cryptography
Private keys never leave your servers. Only you can create valid tokens with your private key, while GroupVAN servers only need your public key for verification.
</div>

<div class="feature-card" markdown="1">
<div class="feature-icon">⏱️</div>

### Short-lived Tokens
5-minute expiration by default for enhanced security. Automatic expiration handling in all client libraries with support for custom expiration times when needed.
</div>

<div class="feature-card" markdown="1">
<div class="feature-icon">🔄</div>

### Key Rotation Support
Seamless key updates without downtime. Support for multiple active keys during rotation period with secure storage recommendations for production environments.
</div>

<div class="feature-card" markdown="1">
<div class="feature-icon">📦</div>

### Native Package Management
Install via pip, npm, composer, or NuGet. All packages are published to official repositories with semantic versioning and dependency management.
</div>

## Security Model

### RSA256 Algorithm
All tokens are signed using RSA private keys and verified with RSA public keys, ensuring that:
- Only you can create valid tokens with your private key
- GroupVAN servers only need your public key for verification
- Private keys remain secure in your infrastructure

### Token Lifecycle
- Tokens expire after 5 minutes by default
- Automatic expiration handling in all client libraries
- Support for custom expiration times when needed

### Key Management
- Generate RSA key pairs using built-in utilities
- Support for multiple active keys during rotation
- Secure storage recommendations for production environments

## Getting Started

1. **[Generate RSA Keys](quickstart#generating-rsa-keys)** - Create your public/private key pair
2. **[Register Public Key](quickstart#registering-your-public-key)** - Share with your GroupVAN Integration Specialist
3. **[Install Client Library](quickstart#installation)** - Choose your preferred language
4. **[Authenticate](quickstart#authentication)** - Start making authenticated API calls

## Example Usage

### Python
```python
from groupvan_client import GroupVANClient

client = GroupVANClient(
    developer_id="your_developer_id",
    key_id="your_key_id",
    private_key_path="path/to/private_key.pem"
)

token = client.generate_token()
response = client.make_api_call("/api/v3/endpoint", token)
```

### Node.js
```javascript
const { GroupVANClient } = require('@groupvan/client');

const client = new GroupVANClient({
    developerId: 'your_developer_id',
    keyId: 'your_key_id',
    privateKeyPath: 'path/to/private_key.pem'
});

const token = client.generateToken();
const response = await client.makeApiCall('/api/v3/endpoint', token);
```

## Support

- 📖 **[API Documentation](https://api.groupvan.com/docs)** - Full API reference
- 🐛 **[Issue Tracker](https://github.com/federatedops/groupvan-api-client/issues)** - Report bugs or request features
- 👥 **Integration Specialist** - Contact your GroupVAN Integration Specialist for support
- 🔒 **[Security](security)** - Best practices and vulnerability reporting

## Contributing

We welcome contributions! Please see our [Contributing Guide](https://github.com/federatedops/groupvan-api-client/blob/main/CONTRIBUTING.md) for details on:
- Code style guidelines
- Testing requirements
- Pull request process
- Development setup

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/federatedops/groupvan-api-client/blob/main/LICENSE) file for details.