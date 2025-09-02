# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within GroupVAN API Client, please contact your GroupVAN Integration Specialist. All security vulnerabilities will be promptly addressed.

Please do not report security vulnerabilities through public GitHub issues.

## Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the problem and determine the affected versions.
2. Audit code to find any potential similar problems.
3. Prepare fixes for all releases still under maintenance.
4. Release new security fix versions.

## Security Best Practices

When using GroupVAN API Client libraries:

### Private Key Management

- **Never commit private keys** to version control
- Store private keys in secure locations:
  - Environment variables
  - Secure key management services (AWS KMS, Azure Key Vault, etc.)
  - Encrypted configuration files (not in repository)
- Use different keys for different environments (dev, staging, production)

### Token Security

- Tokens expire after 5 minutes by default
- Do not log or display tokens in plain text
- Transmit tokens only over HTTPS
- Store tokens in memory, not in persistent storage

### Key Rotation

- Rotate keys at least every 90 days
- Support multiple active keys during rotation
- Revoke compromised keys immediately

### Dependencies

- Keep all dependencies up to date
- Regularly audit dependencies for vulnerabilities
- Use tools like:
  - Python: `safety check`
  - Node.js: `npm audit`
  - PHP: `composer audit`
  - C#: `dotnet list package --vulnerable`

## Security Checklist

Before deploying to production:

- [ ] Private keys are stored securely
- [ ] No sensitive data in code or configuration files
- [ ] HTTPS is enforced for all API calls
- [ ] Error messages don't expose sensitive information
- [ ] Logging doesn't include tokens or keys
- [ ] Dependencies are up to date
- [ ] Security headers are properly configured
- [ ] Rate limiting is implemented
- [ ] Input validation is in place

## Contact

For any security concerns, please contact your GroupVAN Integration Specialist.