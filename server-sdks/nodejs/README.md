# GroupVAN Node.js Client Library

Node.js client for authenticating with GroupVAN V3 APIs using JWT tokens with RSA256.

## Installation

```bash
npm install jsonwebtoken axios
```

Or using package.json:
```bash
npm install
```

## Quick Start

```javascript
const { GroupVANClient, generateRSAKeyPair } = require('./client');

// Generate RSA key pair
const { privateKey, publicKey } = generateRSAKeyPair();

// Initialize client
const client = new GroupVANClient(
    'your_developer_id',
    'your_key_id',
    privateKey  // RSA private key
);

// Generate JWT token
const token = client.generateJWT();

// Make API calls
const catalogs = await client.listCatalogs(10);
const catalog = await client.getCatalog('catalog_123');
```

## RSA Key Management

### Generate New Key Pair

```javascript
const { generateRSAKeyPair } = require('./client');
const fs = require('fs');

// Generate 2048-bit RSA key pair
const { privateKey, publicKey } = generateRSAKeyPair(2048);

// Save keys to files
fs.writeFileSync('private_key.pem', privateKey);
fs.writeFileSync('public_key.pem', publicKey);

console.log('Public key to share with GroupVAN:');
console.log(publicKey);
```

### Load Existing Keys

```javascript
const fs = require('fs');
const { GroupVANClient } = require('./client');

// Load private key from file
const privateKey = fs.readFileSync('private_key.pem', 'utf8');

const client = new GroupVANClient(
    'your_developer_id',
    'your_key_id',
    privateKey
);
```

## JWT Token Generation

Tokens are automatically generated with these claims:

```javascript
{
    aud: 'groupvan',
    iss: 'your_developer_id',
    kid: 'your_key_id',
    exp: currentTime + 300,  // 5 minutes
    iat: currentTime
}
```

With header:
```javascript
{
    alg: 'RS256',
    typ: 'JWT',
    kid: 'your_key_id',
    'gv-ver': 'GV-JWT-V1'
}
```

Custom expiration:
```javascript
// Generate token with 10-minute expiration
const token = client.generateJWT(600);
```

## API Methods

### List Catalogs
```javascript
const catalogs = await client.listCatalogs(10, 0);
console.log(`Found ${catalogs.items ? catalogs.items.length : 0} catalogs`);
```

### Get Catalog
```javascript
const catalog = await client.getCatalog('catalog_123');
console.log(`Catalog name: ${catalog.name}`);
```

### Custom Requests
```javascript
const response = await client.makeAuthenticatedRequest(
    'POST',
    '/catalogs',
    {
        name: 'New Catalog',
        type: 'products'
    }
);
```

## Token Verification

Verify tokens using the public key (server-side operation):

```javascript
const { verifyJWT } = require('./client');

const result = verifyJWT(token, publicKey);
if (result.valid) {
    console.log('Token is valid:', result.payload);
} else {
    console.log('Token verification failed:', result.error);
}
```

## Environment Variables

```bash
export GROUPVAN_DEVELOPER_ID="your_developer_id"
export GROUPVAN_KEY_ID="your_key_id"
export GROUPVAN_PRIVATE_KEY_PATH="/path/to/private_key.pem"
export GROUPVAN_API_URL="https://api.groupvan.com/v3"
```

Load from environment:
```javascript
const fs = require('fs');
const { GroupVANClient } = require('./client');

const privateKey = fs.readFileSync(
    process.env.GROUPVAN_PRIVATE_KEY_PATH,
    'utf8'
);

const client = new GroupVANClient(
    process.env.GROUPVAN_DEVELOPER_ID,
    process.env.GROUPVAN_KEY_ID,
    privateKey,
    process.env.GROUPVAN_API_URL
);
```

## Error Handling

```javascript
const { GroupVANClient } = require('./client');

try {
    const catalog = await client.getCatalog('catalog_123');
} catch (error) {
    if (error.message.includes('401')) {
        console.error('Authentication failed - check your credentials');
    } else if (error.message.includes('404')) {
        console.error('Catalog not found');
    } else {
        console.error('Error:', error.message);
    }
}
```

## Complete Example

```javascript
const { 
    GroupVANClient, 
    generateRSAKeyPair, 
    verifyJWT 
} = require('./client');
const jwt = require('jsonwebtoken');

async function main() {
    console.log('='.repeat(60));
    console.log('GroupVAN JWT Authentication Example (RSA256)');
    console.log('='.repeat(60));

    // Generate RSA keys
    const { privateKey, publicKey } = generateRSAKeyPair();
    
    console.log('\nPublic Key (share with GroupVAN):');
    console.log(publicKey.substring(0, 200) + '...');
    
    // Initialize client
    const client = new GroupVANClient(
        'dev_abc123',
        'key_xyz789',
        privateKey
    );
    
    // Generate token
    const token = client.generateJWT();
    console.log(`\nGenerated Token: ${token.substring(0, 50)}...`);
    
    // Decode token to show claims
    const decoded = jwt.decode(token);
    console.log('\nToken claims:', JSON.stringify(decoded, null, 2));
    
    // Verify token with public key
    const verification = verifyJWT(token, publicKey);
    if (verification.valid) {
        console.log('\n✓ Token verified successfully!');
    } else {
        console.log('\n✗ Token verification failed:', verification.error);
    }
    
    // Example API calls (uncomment to test)
    /*
    try {
        const catalogs = await client.listCatalogs(5);
        console.log(`\nFound ${catalogs.items ? catalogs.items.length : 0} catalogs`);
        
        if (catalogs.items && catalogs.items.length > 0) {
            const catalogId = catalogs.items[0].id;
            const catalog = await client.getCatalog(catalogId);
            console.log(`First catalog: ${catalog.name}`);
        }
    } catch (error) {
        console.error('API Error:', error.message);
    }
    */
}

if (require.main === module) {
    main().catch(console.error);
}
```

## Running the Example

```bash
node client.js
```

## API Reference

### Class: `GroupVANClient`

#### Constructor
```javascript
new GroupVANClient(developerId, keyId, privateKeyPem, baseUrl)
```
- `developerId`: Your developer ID
- `keyId`: Your key ID
- `privateKeyPem`: RSA private key in PEM format
- `baseUrl`: API base URL (optional, defaults to https://api.groupvan.com/v3)

#### Methods

- `generateJWT(expiresIn)`: Generate JWT token (expiresIn in seconds, default 300)
- `makeAuthenticatedRequest(method, endpoint, data, params)`: Make API request
- `getCatalog(catalogId)`: Get catalog by ID
- `listCatalogs(limit, offset)`: List catalogs
- `createCatalog(catalogData)`: Create new catalog

### Functions

#### `generateRSAKeyPair(keySize)`
Generate RSA key pair
- `keySize`: Key size in bits (default 2048)
- Returns: `{ privateKey, publicKey }`

#### `verifyJWT(token, publicKeyPem)`
Verify JWT token with public key
- `token`: JWT token to verify
- `publicKeyPem`: RSA public key in PEM format
- Returns: `{ valid: boolean, payload?: object, error?: string }`

## Dependencies

- `jsonwebtoken@^9.0.0` - JWT token generation and validation
- `axios@^1.6.0` - HTTP client
- `crypto` - Built-in Node.js crypto module

## Security Notes

1. **Private Key Security**: Never commit private keys to version control
2. **Key Storage**: Use secure key management systems in production
3. **Token Expiration**: Keep tokens short-lived (5-15 minutes)
4. **HTTPS Only**: Always use HTTPS in production
5. **Key Rotation**: Implement regular key rotation

## Troubleshooting

### Module not found error
```bash
npm install jsonwebtoken axios
```

### JWT verification error
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
node client.js

# Run with custom credentials
GROUPVAN_DEVELOPER_ID=dev_123 node client.js

# Run tests (if available)
npm test
```

## TypeScript Support

TypeScript definitions can be added:

```typescript
interface GroupVANClientOptions {
    developerId: string;
    keyId: string;
    privateKeyPem: string;
    baseUrl?: string;
}

class GroupVANClient {
    constructor(
        developerId: string,
        keyId: string,
        privateKeyPem: string,
        baseUrl?: string
    );
    
    generateJWT(expiresIn?: number): string;
    
    async makeAuthenticatedRequest<T>(
        method: string,
        endpoint: string,
        data?: any,
        params?: any
    ): Promise<T>;
}
```

## License

MIT License - See LICENSE file for details

## Support

For issues or questions, contact the GroupVAN API team at api@groupvan.com