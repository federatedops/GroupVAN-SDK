# GroupVAN PHP Client Library

PHP client for authenticating with GroupVAN V3 APIs using JWT tokens with RSA256.

## Installation

Using Composer:
```bash
composer require firebase/php-jwt guzzlehttp/guzzle phpseclib/phpseclib:~3.0
```

Or add to composer.json:
```json
{
    "require": {
        "firebase/php-jwt": "^6.0",
        "guzzlehttp/guzzle": "^7.0",
        "phpseclib/phpseclib": "~3.0"
    }
}
```

Then run:
```bash
composer install
```

## Quick Start

```php
<?php
require_once 'vendor/autoload.php';
require_once 'Client.php';

// Generate RSA key pair
$keys = generateRSAKeyPair();
$privateKey = $keys['privateKey'];
$publicKey = $keys['publicKey'];

// Initialize client
$client = new GroupVANClient(
    'your_developer_id',
    'your_key_id',
    $privateKey  // RSA private key
);

// Generate JWT token
$token = $client->generateJWT();

// Make API calls
$catalogs = $client->listCatalogs(10);
$catalog = $client->getCatalog('catalog_123');
```

## RSA Key Management

### Generate New Key Pair

```php
<?php
require_once 'Client.php';

// Generate 2048-bit RSA key pair
$keys = generateRSAKeyPair(2048);
$privateKey = $keys['privateKey'];
$publicKey = $keys['publicKey'];

// Save keys to files
file_put_contents('private_key.pem', $privateKey);
file_put_contents('public_key.pem', $publicKey);

echo "Public key to share with GroupVAN:\n";
echo $publicKey;
```

### Load Existing Keys

```php
<?php
// Load private key from file
$privateKey = file_get_contents('private_key.pem');

$client = new GroupVANClient(
    'your_developer_id',
    'your_key_id',
    $privateKey
);
```

## JWT Token Generation

Tokens are automatically generated with these claims:

```php
[
    'aud' => 'groupvan',
    'iss' => 'your_developer_id',
    'kid' => 'your_key_id',
    'exp' => time() + 300,  // 5 minutes
    'iat' => time()
]
```

With header:
```php
[
    'alg' => 'RS256',
    'typ' => 'JWT',
    'kid' => 'your_key_id',
    'gv-ver' => 'GV-JWT-V1'
]
```

Custom expiration:
```php
// Generate token with 10-minute expiration
$token = $client->generateJWT(600);
```

## API Methods

### List Catalogs
```php
$catalogs = $client->listCatalogs(10, 0);
echo "Found " . count($catalogs['items'] ?? []) . " catalogs\n";
```

### Get Catalog
```php
$catalog = $client->getCatalog('catalog_123');
echo "Catalog name: " . $catalog['name'] . "\n";
```

### Create Catalog
```php
$newCatalog = $client->createCatalog([
    'name' => 'New Catalog',
    'type' => 'products',
    'description' => 'Created from PHP client'
]);
echo "Created catalog with ID: " . $newCatalog['id'] . "\n";
```

### Custom Requests
```php
$response = $client->makeAuthenticatedRequest(
    'POST',
    '/catalogs',
    [
        'name' => 'New Catalog',
        'type' => 'products'
    ]
);
```

## Token Verification

Verify tokens using the public key (server-side operation):

```php
<?php
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

// Verify token with public key
$verification = validateJWT($token, $publicKey);

if ($verification['valid']) {
    echo "✓ Token verified successfully!\n";
    print_r($verification['payload']);
} else {
    echo "✗ Token verification failed: " . $verification['error'] . "\n";
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
```php
<?php
// Load private key from file
$privateKey = file_get_contents(getenv('GROUPVAN_PRIVATE_KEY_PATH'));

$client = new GroupVANClient(
    getenv('GROUPVAN_DEVELOPER_ID'),
    getenv('GROUPVAN_KEY_ID'),
    $privateKey,
    getenv('GROUPVAN_API_URL') ?: 'https://api.groupvan.com/v3'
);
```

## Error Handling

```php
<?php
try {
    $catalog = $client->getCatalog('catalog_123');
} catch (Exception $e) {
    if (strpos($e->getMessage(), '401') !== false) {
        echo "Authentication failed - check your credentials\n";
    } elseif (strpos($e->getMessage(), '404') !== false) {
        echo "Catalog not found\n";
    } else {
        echo "Error: " . $e->getMessage() . "\n";
    }
}
```

## Complete Example

```php
<?php
require_once 'vendor/autoload.php';
require_once 'Client.php';

function main() {
    echo str_repeat('=', 60) . "\n";
    echo "GroupVAN JWT Authentication Example (RSA256)\n";
    echo str_repeat('=', 60) . "\n\n";

    // Generate RSA keys
    $keys = generateRSAKeyPair();
    $privateKey = $keys['privateKey'];
    $publicKey = $keys['publicKey'];
    
    echo "Public Key (share with GroupVAN):\n";
    echo substr($publicKey, 0, 200) . "...\n\n";
    
    // Initialize client
    $client = new GroupVANClient(
        'dev_abc123',
        'key_xyz789',
        $privateKey
    );
    
    // Generate token
    $token = $client->generateJWT();
    echo "Generated Token: " . substr($token, 0, 50) . "...\n\n";
    
    // Decode token to show claims
    $parts = explode('.', $token);
    $payload = json_decode(base64_decode($parts[1]), true);
    echo "Token Claims:\n";
    echo json_encode($payload, JSON_PRETTY_PRINT) . "\n\n";
    
    // Verify token with public key
    $verification = validateJWT($token, $publicKey);
    if ($verification['valid']) {
        echo "✓ Token verified successfully!\n\n";
    } else {
        echo "✗ Token verification failed: " . $verification['error'] . "\n\n";
    }
    
    // Example API calls (uncomment to test)
    /*
    try {
        $catalogs = $client->listCatalogs(5);
        echo "Found " . count($catalogs['items'] ?? []) . " catalogs\n";
        
        if (!empty($catalogs['items'])) {
            $catalogId = $catalogs['items'][0]['id'];
            $catalog = $client->getCatalog($catalogId);
            echo "First catalog: " . $catalog['name'] . "\n";
        }
    } catch (Exception $e) {
        echo "API Error: " . $e->getMessage() . "\n";
    }
    */
}

if (php_sapi_name() === 'cli') {
    main();
}
```

## Running the Example

```bash
php Client.php
```

## API Reference

### Class: `GroupVANClient`

#### Constructor
```php
__construct($developerId, $keyId, $privateKeyPem, $baseUrl = 'https://api.groupvan.com/v3')
```
- `$developerId`: Your developer ID
- `$keyId`: Your key ID
- `$privateKeyPem`: RSA private key in PEM format
- `$baseUrl`: API base URL (optional)

#### Methods

- `generateJWT($expiresIn = 300)`: Generate JWT token
- `makeAuthenticatedRequest($method, $endpoint, $data = null, $params = null)`: Make API request
- `getCatalog($catalogId)`: Get catalog by ID
- `listCatalogs($limit = 10, $offset = 0)`: List catalogs
- `createCatalog($catalogData)`: Create new catalog

### Functions

#### `generateRSAKeyPair($keySize = 2048)`
Generate RSA key pair
- Returns: Array with 'privateKey' and 'publicKey'

#### `validateJWT($token, $publicKeyPem)`
Verify JWT token with public key
- Returns: Array with 'valid' boolean and 'payload' or 'error'

#### `generateJWT($accessKey)`
Generate JWT without client class
- `$accessKey`: Array with developer_id, key_id, and private_key
- Returns: JWT token string

## Dependencies

- `firebase/php-jwt ^6.0` - JWT token generation and validation
- `guzzlehttp/guzzle ^7.0` - HTTP client
- `phpseclib/phpseclib ~3.0` - RSA key generation
- PHP >= 7.4

## Security Notes

1. **Private Key Security**: Never commit private keys to version control
2. **Key Storage**: Use secure key management systems in production
3. **Token Expiration**: Keep tokens short-lived (5-15 minutes)
4. **HTTPS Only**: Always use HTTPS in production
5. **Key Rotation**: Implement regular key rotation

## Troubleshooting

### Class not found error
```bash
composer require firebase/php-jwt guzzlehttp/guzzle phpseclib/phpseclib:~3.0
```

### JWT verification error
- Ensure public key matches private key
- Verify token hasn't expired
- Check system time is synchronized

### Connection errors
- Verify API URL is correct
- Check network connectivity
- Ensure firewall allows HTTPS traffic

### PHP version error
- Requires PHP 7.4 or higher
- Check version: `php -v`

## Testing

```bash
# Run example client
php Client.php

# Run with Composer
composer test

# Run with PHPUnit (if configured)
vendor/bin/phpunit tests/
```

## License

MIT License - See LICENSE file for details

## Support

For issues or questions, contact the GroupVAN API team at api@groupvan.com