# GroupVAN API Client Libraries

Official client libraries for authenticating with GroupVAN V3 APIs using JWT tokens with RSA256 asymmetric cryptography.

## Overview

These client libraries provide a secure and standardized way to authenticate with GroupVAN's V3 APIs. All libraries implement the same authentication pattern using RSA256 (RS256) algorithm for enhanced security through asymmetric cryptography.

## Security Model

- **RSA256 Algorithm**: All tokens are signed using RSA private keys and verified with RSA public keys
- **Asymmetric Cryptography**: Servers only need your public key; private keys remain secure on client side
- **Short-lived Tokens**: Default 5-minute expiration for enhanced security
- **Key Rotation Support**: Multiple keys can be active simultaneously

## Available Client Libraries

| Language | Directory | Package Manager | Version | Documentation |
|----------|-----------|----------------|---------|---------------|
| Python | [`clients/python/`](./clients/python) | pip | ![PyPI](https://img.shields.io/pypi/v/groupvan-client) | [README](./clients/python/README.md) |
| Node.js | [`clients/nodejs/`](./clients/nodejs) | npm | ![npm](https://img.shields.io/npm/v/@groupvan/client) | [README](./clients/nodejs/README.md) |
| PHP | [`clients/php/`](./clients/php) | composer | ![Packagist](https://img.shields.io/packagist/v/groupvan/client) | [README](./clients/php/README.md) |
| C#/.NET | [`clients/csharp/`](./clients/csharp) | NuGet | ![NuGet](https://img.shields.io/nuget/v/GroupVAN.Client) | [README](./clients/csharp/README.md) |

## Quick Start

### 1. Install the Client Library

#### Python
```bash
pip install groupvan-client
```

#### Node.js
```bash
npm install @groupvan/client
```

#### PHP
```bash
composer require groupvan/client
```

#### C#/.NET
```bash
dotnet add package GroupVAN.Client
```

### 2. Generate RSA Key Pair

Each client library includes utilities to generate RSA key pairs:

```bash
# Python
python -m groupvan_client.keygen

# Node.js
npx @groupvan/client keygen

# PHP
vendor/bin/groupvan-keygen

# C#
dotnet groupvan keygen
```

### 3. Register Your Public Key

Share your RSA public key with GroupVAN to register your developer credentials. Keep your private key secure and never share it.

### 4. Generate JWT Tokens

See language-specific documentation for detailed usage:

- [Python Documentation](./clients/python/README.md)
- [Node.js Documentation](./clients/nodejs/README.md)
- [PHP Documentation](./clients/php/README.md)
- [C#/.NET Documentation](./clients/csharp/README.md)

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
- **Issues**: [GitHub Issues](https://github.com/groupvan/groupvan-api-client/issues)
- **Support**: Contact your GroupVAN Integration Specialist

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Versioning

We use [Semantic Versioning](https://semver.org/). For the versions available, see the [tags on this repository](https://github.com/groupvan/groupvan-api-client/tags).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.