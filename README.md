# GroupVAN SDK Libraries

[![Python CI](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/python.yml/badge.svg)](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/python.yml)
[![Node.js CI](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/nodejs.yml/badge.svg)](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/nodejs.yml)
[![PHP CI](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/php.yml/badge.svg)](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/php.yml)
[![.NET CI](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/csharp.yml/badge.svg)](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/csharp.yml)
[![Documentation](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/docs.yml/badge.svg)](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/docs.yml)

Official SDK libraries for authenticating with GroupVAN V3 APIs using JWT tokens with RSA256 asymmetric cryptography.

## Overview

These SDK libraries provide a secure and standardized way to authenticate with GroupVAN's V3 APIs. All libraries implement the same authentication pattern using RSA256 (RS256) algorithm for enhanced security through asymmetric cryptography.

## Security Model

- **RSA256 Algorithm**: All tokens are signed using RSA private keys and verified with RSA public keys
- **Asymmetric Cryptography**: Servers only need your public key; private keys remain secure on client side
- **Short-lived Tokens**: Default 5-minute expiration for enhanced security
- **Key Rotation Support**: Multiple keys can be active simultaneously

## Available SDK Libraries

### Server-Side SDKs

For backend applications and server environments:

| Language | Directory | Package Manager | Version | Documentation |
|----------|-----------|----------------|---------|---------------|
| Python | [`server-sdks/python/`](./server-sdks/python) | pip | ![PyPI](https://img.shields.io/pypi/v/groupvan-server-sdk) | [README](./server-sdks/python/README.md) |
| Node.js | [`server-sdks/nodejs/`](./server-sdks/nodejs) | npm | ![npm](https://img.shields.io/npm/v/@groupvan/server-sdk) | [README](./server-sdks/nodejs/README.md) |
| PHP | [`server-sdks/php/`](./server-sdks/php) | composer | ![Packagist](https://img.shields.io/packagist/v/groupvan/server-sdk) | [README](./server-sdks/php/README.md) |
| C#/.NET | [`server-sdks/csharp/`](./server-sdks/csharp) | NuGet | ![NuGet](https://img.shields.io/nuget/v/GroupVAN.ServerSDK) | [README](./server-sdks/csharp/README.md) |

### Web/Browser SDKs

For frontend applications and browser environments:

| Language | Directory | Package Manager | Installation | Documentation |
|----------|-----------|----------------|--------------|---------------|
| Dart/Flutter | [`web-sdks/dart/`](./web-sdks/dart) | pub | `git: {url: ..., path: web-sdks/dart}` | [README](./web-sdks/dart/README.md) |

## Quick Start

### 1. Install the SDK Library

#### Python
```bash
pip install groupvan-server-sdk
```

#### Node.js
```bash
npm install @groupvan/server-sdk
```

#### PHP
```bash
composer require groupvan/server-sdk
```

#### C#/.NET
```bash
dotnet add package GroupVAN.ServerSDK
```

### 2. Generate RSA Key Pair

Each SDK library includes utilities to generate RSA key pairs:

```bash
# Python
python -m groupvan_server_sdk.keygen

# Node.js
npx @groupvan/server-sdk keygen

# PHP
vendor/bin/groupvan-server-keygen

# C#
dotnet groupvan-server keygen
```

### 3. Register Your Public Key

Share your RSA public key with GroupVAN to register your developer credentials. Keep your private key secure and never share it.

### 4. Generate JWT Tokens

See language-specific documentation for detailed usage:

**Server SDKs:**
- [Python Documentation](./server-sdks/python/README.md)
- [Node.js Documentation](./server-sdks/nodejs/README.md)
- [PHP Documentation](./server-sdks/php/README.md)
- [C#/.NET Documentation](./server-sdks/csharp/README.md)

**Web SDKs:**
- [Dart/Flutter Documentation](./web-sdks/dart/README.md)

## Examples

Working examples for each language can be found in the [`examples/`](./examples) directory.

## API Documentation

For detailed API documentation, visit our [API Documentation](https://api.groupvan.com/docs).

## Security

### Reporting Security Vulnerabilities

If you discover a security vulnerability, please contact your GroupVAN Integration Specialist instead of using the issue tracker.

### Best Practices

1. **Never commit private keys** to version control
2. **Rotate keys regularly** (recommended every 90 days)
3. **Use environment variables** or secure vaults for key storage
4. **Monitor token expiration** and refresh as needed
5. **Implement proper error handling** for authentication failures

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## Support

- **Documentation**: [https://api.groupvan.com/docs](https://api.groupvan.com/docs)
- **Issues**: [GitHub Issues](https://github.com/federatedops/GroupVAN-SDK/issues)
- **Support**: Contact your GroupVAN Integration Specialist

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Versioning

We use [Semantic Versioning](https://semver.org/). For the versions available, see the [tags on this repository](https://github.com/federatedops/GroupVAN-SDK/tags).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.