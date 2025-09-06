---
layout: default
title: Security
nav_order: 3
---

# Security Best Practices
{: .no_toc }

Essential security guidelines for using GroupVAN API Client libraries in production.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

Security is paramount when implementing API authentication. This guide covers best practices for keeping your GroupVAN integration secure.

## Private Key Management

### Never Commit Private Keys

⚠️ **Critical**: Private keys should NEVER be committed to version control.
{: .label .label-red }

Add these entries to your `.gitignore`:
```gitignore
# Private keys
*.pem
*.key
*.p12
*.pfx
private_key*
id_rsa*
*_private*
```

### Secure Storage Options

#### Environment Variables
```bash
# Store key content directly (base64 encoded)
export GROUPVAN_PRIVATE_KEY=$(base64 < private_key.pem)

# Reference key file path
export GROUPVAN_PRIVATE_KEY_PATH=/secure/location/private_key.pem
```

#### Key Management Services

**AWS Secrets Manager**
```python
import boto3
import json

def get_private_key():
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId='groupvan/private-key')
    return json.loads(response['SecretString'])['private_key']
```

**Azure Key Vault**
```csharp
using Azure.Security.KeyVault.Secrets;

var client = new SecretClient(vaultUri, new DefaultAzureCredential());
KeyVaultSecret secret = await client.GetSecretAsync("groupvan-private-key");
string privateKey = secret.Value;
```

**HashiCorp Vault**
```javascript
const vault = require('node-vault')({
  endpoint: 'https://vault.company.com',
  token: process.env.VAULT_TOKEN
});

const { data } = await vault.read('secret/groupvan/private-key');
const privateKey = data.private_key;
```

### File Permissions

Ensure private key files have restrictive permissions:

```bash
# Unix/Linux/macOS
chmod 600 private_key.pem  # Read/write for owner only
chown $USER:$USER private_key.pem

# Verify permissions
ls -la private_key.pem
# Should show: -rw------- 1 user user 1679 Jan 1 00:00 private_key.pem
```

## Token Security

### Token Expiration

Tokens expire after 5 minutes by default. This short lifespan reduces the risk if a token is compromised.

```python
# Custom expiration (not recommended for production)
token = client.generate_token(expiration_minutes=10)  # 10 minutes

# Default (recommended)
token = client.generate_token()  # 5 minutes
```

### Token Handling

**DO:**
- ✅ Generate tokens just before API calls
- ✅ Store tokens in memory only
- ✅ Use HTTPS for all API calls
- ✅ Implement token refresh logic

**DON'T:**
- ❌ Log tokens in plain text
- ❌ Store tokens in databases
- ❌ Share tokens between users
- ❌ Cache tokens in files

### Secure Transmission

Always use HTTPS for API calls:

```python
# Good - HTTPS
response = requests.get(
    "https://api.groupvan.com/v3/users",
    headers={"Authorization": f"Bearer {token}"}
)

# Bad - HTTP (never do this!)
# response = requests.get("http://api.groupvan.com/v3/users", ...)
```

## Key Rotation

### Why Rotate Keys?

- Limits exposure if a key is compromised
- Compliance with security policies
- Best practice for long-running systems

### Rotation Strategy

1. **Generate new key pair**
```bash
# Generate new key with timestamp
timestamp=$(date +%Y%m%d)
openssl genrsa -out private_key_${timestamp}.pem 2048
openssl rsa -in private_key_${timestamp}.pem -pubout -out public_key_${timestamp}.pem
```

2. **Register new public key** with GroupVAN Integration Specialist

3. **Update application** to use new key
```python
# Support multiple keys during transition
if datetime.now() < transition_date:
    client = GroupVANClient(key_id="KEY001", private_key_path="old_key.pem")
else:
    client = GroupVANClient(key_id="KEY002", private_key_path="new_key.pem")
```

4. **Revoke old key** after transition period

### Automated Rotation

```python
import os
from datetime import datetime, timedelta

class KeyRotationManager:
    def __init__(self):
        self.keys = self.load_keys()
    
    def get_current_key(self):
        """Get the most recent valid key"""
        now = datetime.now()
        for key in self.keys:
            if key['valid_from'] <= now <= key['valid_until']:
                return key
        raise Exception("No valid key found")
    
    def should_rotate(self):
        """Check if rotation is needed"""
        current_key = self.get_current_key()
        days_until_expiry = (current_key['valid_until'] - datetime.now()).days
        return days_until_expiry < 7  # Rotate 7 days before expiry
```

## Vulnerability Reporting

If you discover a security vulnerability:

1. **DO NOT** create a public GitHub issue
2. Contact your GroupVAN Integration Specialist immediately
3. Provide detailed information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Checklist

Use this checklist before deploying to production:

### Development
- [ ] Private keys are in `.gitignore`
- [ ] No hardcoded credentials in source code
- [ ] Environment variables used for configuration
- [ ] Error messages don't expose sensitive data

### Infrastructure
- [ ] Private keys stored securely (KMS, Vault, etc.)
- [ ] File permissions set correctly (600 for private keys)
- [ ] HTTPS enforced for all API calls
- [ ] Network security groups/firewalls configured

### Application
- [ ] Token expiration handled properly
- [ ] Logging excludes sensitive data
- [ ] Input validation implemented
- [ ] Rate limiting configured
- [ ] Error handling doesn't leak information

### Monitoring
- [ ] Failed authentication attempts logged
- [ ] Unusual API usage patterns monitored
- [ ] Key rotation schedule established
- [ ] Security alerts configured

## Common Security Mistakes

### 1. Exposing Keys in Logs

❌ **Bad:**
```python
logger.info(f"Using private key: {private_key}")
logger.debug(f"Generated token: {token}")
```

✅ **Good:**
```python
logger.info(f"Using key ID: {key_id}")
logger.debug("Token generated successfully")
```

### 2. Storing Keys in Code

❌ **Bad:**
```javascript
const privateKey = `-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
-----END RSA PRIVATE KEY-----`;
```

✅ **Good:**
```javascript
const privateKey = fs.readFileSync(process.env.PRIVATE_KEY_PATH);
```

### 3. Weak File Permissions

❌ **Bad:**
```bash
-rw-rw-rw- 1 user user 1679 Jan 1 00:00 private_key.pem
```

✅ **Good:**
```bash
-rw------- 1 user user 1679 Jan 1 00:00 private_key.pem
```

### 4. Long Token Expiration

❌ **Bad:**
```python
token = client.generate_token(expiration_minutes=1440)  # 24 hours
```

✅ **Good:**
```python
token = client.generate_token()  # Default 5 minutes
```

## Compliance

### GDPR Considerations
- Implement proper access controls
- Log access to personal data
- Support data deletion requests
- Encrypt sensitive data at rest

### PCI DSS Requirements
- Use strong cryptography (RSA-2048 minimum)
- Protect cryptographic keys
- Restrict access on need-to-know basis
- Regular security testing

### SOC 2 Controls
- Document key management procedures
- Implement audit logging
- Regular security reviews
- Incident response plan

## Additional Resources

- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [NIST Key Management Guidelines](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57pt1r5.pdf)
- [JWT Best Practices](https://datatracker.ietf.org/doc/html/rfc8725)
- [GroupVAN Security Policy](https://github.com/federatedops/GroupVAN-SDK/blob/main/SECURITY.md)