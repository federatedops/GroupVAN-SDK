# GroupVAN Web SDK Libraries

Web SDK libraries for browser and frontend applications. These libraries are optimized for web environments where security considerations differ from server-side applications.

## Available Libraries

| Language/Framework | Directory | Installation | Documentation |
|-------------------|-----------|--------------|---------------|
| Dart/Flutter | [`dart/`](./dart) | `git: {url: ..., path: web-sdks/dart}` | [README](./dart/README.md) |

## Key Differences from Server SDKs

### Security Considerations
- **Public Key Only**: Web SDKs only store and use public keys for token verification
- **No Private Keys**: Private keys should never be embedded in web applications
- **Token Validation**: Focus on validating tokens received from your backend services
- **CORS Handling**: Built-in support for cross-origin resource sharing

### Use Cases
- **Token Verification**: Validate JWT tokens received from your backend
- **API Communication**: Secure communication with GroupVAN APIs from frontend
- **Mobile Applications**: Flutter/Dart support for mobile app development
- **Web Applications**: Browser-based applications with GroupVAN integration

## Installation Examples

### Dart/Flutter
Add to your `pubspec.yaml`:
```yaml
dependencies:
  groupvan_web_sdk:
    git:
      url: https://github.com/federatedops/GroupVAN-SDK.git
      path: web-sdks/dart
```

## Security Best Practices

1. **Never embed private keys** in web applications
2. **Validate tokens server-side** for critical operations  
3. **Use HTTPS** for all API communications
4. **Implement proper CORS** policies
5. **Store tokens securely** (secure storage, not localStorage for sensitive data)

## Contributing

See the main [Contributing Guide](../CONTRIBUTING.md) for details on contributing to web SDK libraries.

## Support

- **Documentation**: [https://api.groupvan.com/docs](https://api.groupvan.com/docs)
- **Issues**: [GitHub Issues](https://github.com/federatedops/GroupVAN-SDK/issues)
- **Support**: Contact your GroupVAN Integration Specialist