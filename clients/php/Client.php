<?php
/**
 * GroupVAN JWT Authentication Client for PHP
 * 
 * This example demonstrates how to generate JWTs and make authenticated
 * requests to V3 APIs using JWT authentication with RSA256.
 * 
 * Installation:
 *   composer require firebase/php-jwt
 *   composer require guzzlehttp/guzzle
 *   composer require phpseclib/phpseclib:~3.0
 * 
 * Or without Composer, download:
 *   https://github.com/firebase/php-jwt
 *   https://github.com/guzzle/guzzle
 *   https://github.com/phpseclib/phpseclib
 * 
 * Usage:
 *   php Client.php
 */

require_once 'vendor/autoload.php'; // If using Composer

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\RequestException;
use phpseclib3\Crypt\RSA;
use phpseclib3\Crypt\PublicKeyLoader;

/**
 * GroupVAN API Client for authenticated V3 API requests using RSA256
 */
class GroupVANClient {
    private $developerId;
    private $keyId;
    private $privateKeyPem;
    private $baseUrl;
    private $httpClient;

    /**
     * Initialize the client with developer credentials
     * 
     * @param string $developerId Your developer ID
     * @param string $keyId Your key ID
     * @param string $privateKeyPem Your RSA private key in PEM format
     * @param string $baseUrl API base URL (optional)
     */
    public function __construct($developerId, $keyId, $privateKeyPem, $baseUrl = 'https://api.groupvan.com/v3') {
        $this->developerId = $developerId;
        $this->keyId = $keyId;
        $this->privateKeyPem = $privateKeyPem;
        $this->baseUrl = $baseUrl;
        $this->httpClient = new Client([
            'base_uri' => $baseUrl,
            'timeout' => 30.0,
        ]);
    }

    /**
     * Generate a JWT token for authentication using RSA256
     * 
     * @param int $expiresIn Token expiry in seconds (default 300)
     * @return string Signed JWT token
     */
    public function generateJWT($expiresIn = 300) {
        $currentTime = time();
        
        // Create JWT claims
        $claims = [
            'aud' => 'groupvan',
            'iss' => $this->developerId,
            'kid' => $this->keyId,
            'exp' => $currentTime + $expiresIn,
            'iat' => $currentTime
        ];

        // Set custom header
        $headers = [
            'kid' => $this->keyId,
            'gv-ver' => 'GV-JWT-V1'
        ];

        // Generate JWT with RSA256
        $token = JWT::encode($claims, $this->privateKeyPem, 'RS256', null, $headers);

        return $token;
    }

    /**
     * Make an authenticated request to the V3 API
     * 
     * @param string $method HTTP method (GET, POST, etc.)
     * @param string $endpoint API endpoint path
     * @param array|null $data Request body data (for POST/PUT)
     * @param array|null $params Query parameters
     * @return array Response data
     * @throws Exception on API error
     */
    public function makeAuthenticatedRequest($method, $endpoint, $data = null, $params = null) {
        // Generate fresh JWT token
        $token = $this->generateJWT();

        // Prepare request options
        $options = [
            'headers' => [
                'Authorization' => 'Bearer ' . $token,
                'Content-Type' => 'application/json'
            ]
        ];

        if ($data !== null) {
            $options['json'] = $data;
        }

        if ($params !== null) {
            $options['query'] = $params;
        }

        try {
            $response = $this->httpClient->request($method, $endpoint, $options);
            $body = $response->getBody()->getContents();
            return json_decode($body, true);
        } catch (RequestException $e) {
            if ($e->hasResponse()) {
                $response = $e->getResponse();
                $error = $response->getBody()->getContents();
                throw new Exception("API Error: {$response->getStatusCode()} - $error");
            } else {
                throw new Exception("Request error: " . $e->getMessage());
            }
        }
    }

    /**
     * Example: Get a catalog by ID
     * 
     * @param string $catalogId The catalog ID
     * @return array Catalog data
     */
    public function getCatalog($catalogId) {
        return $this->makeAuthenticatedRequest('GET', "/catalogs/$catalogId");
    }

    /**
     * Example: List available catalogs
     * 
     * @param int $limit Number of results to return
     * @param int $offset Pagination offset
     * @return array List of catalogs
     */
    public function listCatalogs($limit = 10, $offset = 0) {
        return $this->makeAuthenticatedRequest('GET', '/catalogs', null, [
            'limit' => $limit,
            'offset' => $offset
        ]);
    }

    /**
     * Example: Create a new catalog
     * 
     * @param array $catalogData Catalog data to create
     * @return array Created catalog
     */
    public function createCatalog($catalogData) {
        return $this->makeAuthenticatedRequest('POST', '/catalogs', $catalogData);
    }
}

/**
 * Generate an RSA key pair for JWT signing
 * 
 * @param int $keySize Key size in bits (default 2048)
 * @return array Array with 'privateKey' and 'publicKey' in PEM format
 */
function generateRSAKeyPair($keySize = 2048) {
    $key = RSA::createKey($keySize);
    
    return [
        'privateKey' => $key->toString('PKCS8'),
        'publicKey' => $key->getPublicKey()->toString('PKCS8')
    ];
}

/**
 * Generate JWT without using the client class
 */
function generateJWT($accessKey) {
    $currentTime = time();
    
    $claims = [
        'aud' => 'groupvan',
        'iss' => $accessKey['developer_id'],
        'kid' => $accessKey['key_id'],
        'exp' => $currentTime + 300,
        'iat' => $currentTime
    ];
    
    $headers = [
        'kid' => $accessKey['key_id'],
        'gv-ver' => 'GV-JWT-V1'
    ];
    
    // Use RSA256 algorithm
    return JWT::encode($claims, $accessKey['private_key'], 'RS256', null, $headers);
}

/**
 * Validate JWT using RSA public key
 */
function validateJWT($token, $publicKeyPem) {
    try {
        $decoded = JWT::decode($token, new Key($publicKeyPem, 'RS256'));
        
        // Verify audience
        if ($decoded->aud !== 'groupvan') {
            throw new Exception('Invalid audience');
        }
        
        return [
            'valid' => true,
            'payload' => (array) $decoded
        ];
    } catch (Exception $e) {
        return [
            'valid' => false,
            'error' => $e->getMessage()
        ];
    }
}

/**
 * Example usage demonstrating JWT generation and API calls with RSA256
 */
function main() {
    echo str_repeat('=', 60) . "\n";
    echo "GroupVAN JWT Authentication Example for PHP (RSA256)\n";
    echo str_repeat('=', 60) . "\n\n";

    // Example 1: Generate RSA key pair
    echo "1. Generating RSA key pair:\n";
    $keys = generateRSAKeyPair();
    $privateKey = $keys['privateKey'];
    $publicKey = $keys['publicKey'];
    
    echo "Private Key (keep this secret!):\n";
    echo substr($privateKey, 0, 200) . "...\n\n";
    echo "Public Key (share with server):\n";
    echo substr($publicKey, 0, 200) . "...\n\n";

    // Example 2: Generate JWT with RSA256
    echo "2. Generating JWT:\n";
    
    $accessKey = [
        'developer_id' => 'dev_abc123',
        'key_id' => 'key_xyz789',
        'private_key' => $privateKey  // RSA private key instead of shared secret
    ];

    $token = generateJWT($accessKey);
    echo "Generated Token: " . substr($token, 0, 50) . "...\n";
    
    // Decode token to show claims (for debugging)
    $parts = explode('.', $token);
    $payload = json_decode(base64_decode($parts[1]), true);
    echo "\nToken Claims:\n";
    echo json_encode($payload, JSON_PRETTY_PRINT) . "\n";
    
    // Decode header to show algorithm
    $header = json_decode(base64_decode($parts[0]), true);
    echo "\nToken Header:\n";
    echo json_encode($header, JSON_PRETTY_PRINT) . "\n";

    // Example 3: Verify token with public key (server-side operation)
    echo "\n3. Verifying token with public key:\n";
    $verification = validateJWT($token, $publicKey);
    if ($verification['valid']) {
        echo "✓ Token verified successfully!\n";
        echo "Verified payload:\n";
        echo json_encode($verification['payload'], JSON_PRETTY_PRINT) . "\n";
    } else {
        echo "✗ Token verification failed: " . $verification['error'] . "\n";
    }

    // Example 4: Using the client class
    echo "\n4. Using GroupVAN Client Class:\n";
    
    // Initialize client with RSA private key
    $client = new GroupVANClient(
        'your_developer_id',
        'your_key_id',
        $privateKey,  // Use RSA private key
        'http://localhost:5000/v3'  // Use your actual API URL
    );

    try {
        // Generate a token
        $clientToken = $client->generateJWT();
        echo "\nClient Token: " . substr($clientToken, 0, 50) . "...\n";

        // Example API calls (uncomment to test with real API)
        /*
        echo "\nListing catalogs...\n";
        $catalogs = $client->listCatalogs(5);
        $catalogCount = isset($catalogs['items']) ? count($catalogs['items']) : 0;
        echo "Found $catalogCount catalogs\n";

        if (!empty($catalogs['items'])) {
            $catalogId = $catalogs['items'][0]['id'];
            echo "\nGetting catalog $catalogId...\n";
            $catalog = $client->getCatalog($catalogId);
            echo "Catalog name: {$catalog['name']}\n";
        }

        echo "\nCreating a new catalog...\n";
        $newCatalog = $client->createCatalog([
            'name' => 'Test Catalog',
            'description' => 'Created from PHP client with RSA256',
            'type' => 'products'
        ]);
        echo "Created catalog with ID: {$newCatalog['id']}\n";
        */

    } catch (Exception $e) {
        echo "Error: " . $e->getMessage() . "\n";
    }

    // Example 5: Using plain cURL without libraries
    echo "\n5. Plain cURL Example:\n";
    echo "Example cURL function created for RSA256 JWT\n";
    
    // Example 6: Important notes
    echo "\n" . str_repeat('=', 60) . "\n";
    echo "Important Notes:\n";
    echo "- Server only needs your PUBLIC key to verify tokens\n";
    echo "- Keep your PRIVATE key secure and never share it\n";
    echo "- Use RS256 algorithm for enhanced security\n";
    echo "- Tokens are now signed with asymmetric cryptography\n";
    echo str_repeat('=', 60) . "\n";
}

/**
 * Helper function to save RSA keys to files
 */
function saveKeysToFiles($privateKey, $publicKey, $privateKeyPath = 'private_key.pem', $publicKeyPath = 'public_key.pem') {
    file_put_contents($privateKeyPath, $privateKey);
    file_put_contents($publicKeyPath, $publicKey);
    echo "Keys saved to $privateKeyPath and $publicKeyPath\n";
}

/**
 * Helper function to load RSA keys from files
 */
function loadKeysFromFiles($privateKeyPath, $publicKeyPath = null) {
    $privateKey = file_get_contents($privateKeyPath);
    $publicKey = $publicKeyPath ? file_get_contents($publicKeyPath) : null;
    return [
        'privateKey' => $privateKey,
        'publicKey' => $publicKey
    ];
}

// Run example if executed directly
if (php_sapi_name() === 'cli') {
    main();
}
