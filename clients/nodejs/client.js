/**
 * GroupVAN JWT Authentication Client for Node.js
 * 
 * This example demonstrates how to generate JWTs and make authenticated
 * requests to V3 APIs using JWT authentication with RSA256.
 * 
 * Installation:
 *   npm install jsonwebtoken axios crypto
 * 
 * Usage:
 *   node client.js
 */

const jwt = require('jsonwebtoken');
const axios = require('axios');
const crypto = require('crypto');
const fs = require('fs');

/**
 * GroupVAN API Client for authenticated V3 API requests using RSA256
 */
class GroupVANClient {
    /**
     * Initialize the client with developer credentials
     * @param {string} developerId - Your developer ID
     * @param {string} keyId - Your key ID
     * @param {string} privateKeyPem - Your RSA private key in PEM format
     * @param {string} baseUrl - API base URL (optional)
     */
    constructor(developerId, keyId, privateKeyPem, baseUrl = 'https://api.groupvan.com/v3') {
        this.developerId = developerId;
        this.keyId = keyId;
        this.privateKeyPem = privateKeyPem;
        this.baseUrl = baseUrl;
    }

    /**
     * Generate a JWT token for authentication using RSA256
     * @param {number} expiresIn - Token expiry in seconds (default 300)
     * @returns {string} Signed JWT token
     */
    generateJWT(expiresIn = 300) {
        const currentTime = Math.floor(Date.now() / 1000);
        
        // Create JWT claims
        const claims = {
            aud: 'groupvan',
            iss: this.developerId,
            kid: this.keyId,
            exp: currentTime + expiresIn,
            iat: currentTime
        };

        // Generate JWT with RSA256 algorithm
        const token = jwt.sign(
            claims,
            this.privateKeyPem,
            {
                algorithm: 'RS256',
                header: {
                    alg: 'RS256',
                    typ: 'JWT',
                    kid: this.keyId,
                    'gv-ver': 'GV-JWT-V1'
                }
            }
        );

        return token;
    }

    /**
     * Make an authenticated request to the V3 API
     * @param {string} method - HTTP method (GET, POST, etc.)
     * @param {string} endpoint - API endpoint path
     * @param {object} data - Request body data (for POST/PUT)
     * @param {object} params - Query parameters
     * @returns {Promise} Axios response promise
     */
    async makeAuthenticatedRequest(method, endpoint, data = null, params = null) {
        // Generate fresh JWT token
        const token = this.generateJWT();

        // Prepare request configuration
        const config = {
            method: method,
            url: `${this.baseUrl}${endpoint}`,
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        };

        if (data) {
            config.data = data;
        }

        if (params) {
            config.params = params;
        }

        try {
            const response = await axios(config);
            return response.data;
        } catch (error) {
            if (error.response) {
                // Server responded with error
                throw new Error(`API Error: ${error.response.status} - ${JSON.stringify(error.response.data)}`);
            } else if (error.request) {
                // Request made but no response
                throw new Error('No response from server');
            } else {
                // Request setup error
                throw new Error(`Request error: ${error.message}`);
            }
        }
    }

    /**
     * Example: Get a catalog by ID
     * @param {string} catalogId - The catalog ID
     * @returns {Promise<object>} Catalog data
     */
    async getCatalog(catalogId) {
        return this.makeAuthenticatedRequest('GET', `/catalogs/${catalogId}`);
    }

    /**
     * Example: List available catalogs
     * @param {number} limit - Number of results to return
     * @param {number} offset - Pagination offset
     * @returns {Promise<object>} List of catalogs
     */
    async listCatalogs(limit = 10, offset = 0) {
        return this.makeAuthenticatedRequest('GET', '/catalogs', null, { limit, offset });
    }

    /**
     * Example: Create a new catalog
     * @param {object} catalogData - Catalog data to create
     * @returns {Promise<object>} Created catalog
     */
    async createCatalog(catalogData) {
        return this.makeAuthenticatedRequest('POST', '/catalogs', catalogData);
    }
}

/**
 * Generate an RSA key pair for JWT signing
 * @param {number} keySize - Key size in bits (default 2048)
 * @returns {object} Object with privateKey and publicKey in PEM format
 */
function generateRSAKeyPair(keySize = 2048) {
    const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: keySize,
        publicKeyEncoding: {
            type: 'spki',
            format: 'pem'
        },
        privateKeyEncoding: {
            type: 'pkcs8',
            format: 'pem'
        }
    });

    return { privateKey, publicKey };
}

/**
 * Verify a JWT token using RSA public key
 * @param {string} token - JWT token to verify
 * @param {string} publicKeyPem - RSA public key in PEM format
 * @returns {object} Decoded token payload if valid
 */
function verifyJWT(token, publicKeyPem) {
    try {
        const payload = jwt.verify(token, publicKeyPem, {
            algorithms: ['RS256'],
            audience: 'groupvan'
        });
        return { valid: true, payload };
    } catch (error) {
        return { valid: false, error: error.message };
    }
}

/**
 * Example usage demonstrating JWT generation and API calls with RSA256
 */
async function main() {
    console.log('='.repeat(60));
    console.log('GroupVAN JWT Authentication Example for Node.js (RSA256)');
    console.log('='.repeat(60));

    // Example 1: Generate RSA key pair
    console.log('\n1. Generating RSA key pair:');
    const { privateKey, publicKey } = generateRSAKeyPair();
    
    console.log('Private Key (keep this secret!):');
    console.log(privateKey.substring(0, 200) + '...');
    console.log('\nPublic Key (share with server):');
    console.log(publicKey.substring(0, 200) + '...');

    // Example 2: Generate JWT with RSA256
    console.log('\n2. Generating JWT:');
    
    const accessKey = {
        developer_id: "dev_abc123",
        key_id: "key_xyz789",
        private_key: privateKey  // RSA private key instead of shared secret
    };

    const currentTime = Math.floor(Date.now() / 1000);
    const token = jwt.sign(
        {
            aud: "groupvan",
            iss: accessKey.developer_id,
            kid: accessKey.key_id,
            exp: currentTime + 300,
            iat: currentTime
        },
        accessKey.private_key,
        {
            algorithm: 'RS256',  // Changed from HS256 to RS256
            header: {
                alg: 'RS256',
                typ: 'JWT',
                kid: accessKey.key_id,
                'gv-ver': 'GV-JWT-V1'
            }
        }
    );

    console.log(`Generated Token: ${token.substring(0, 50)}...`);
    
    // Decode token to show claims (for debugging)
    const decoded = jwt.decode(token);
    console.log('\nToken Claims:');
    console.log(JSON.stringify(decoded, null, 2));
    
    // Decode header to show algorithm
    const header = jwt.decode(token, { complete: true }).header;
    console.log('\nToken Header:');
    console.log(JSON.stringify(header, null, 2));

    // Example 3: Verify token with public key (server-side operation)
    console.log('\n3. Verifying token with public key:');
    const verification = verifyJWT(token, publicKey);
    if (verification.valid) {
        console.log('✓ Token verified successfully!');
        console.log('Verified payload:', JSON.stringify(verification.payload, null, 2));
    } else {
        console.log('✗ Token verification failed:', verification.error);
    }

    // Example 4: Using the client class
    console.log('\n4. Using GroupVAN Client Class:');
    
    // Initialize client with RSA private key
    const client = new GroupVANClient(
        'your_developer_id',
        'your_key_id',
        privateKey,  // Use RSA private key
        'http://localhost:5000/v3'  // Use your actual API URL
    );

    try {
        // Generate a token
        const clientToken = client.generateJWT();
        console.log(`\nClient Token: ${clientToken.substring(0, 50)}...`);

        // Example API calls (uncomment to test with real API)
        /*
        console.log('\nListing catalogs...');
        const catalogs = await client.listCatalogs(5);
        console.log(`Found ${catalogs.items ? catalogs.items.length : 0} catalogs`);

        if (catalogs.items && catalogs.items.length > 0) {
            const catalogId = catalogs.items[0].id;
            console.log(`\nGetting catalog ${catalogId}...`);
            const catalog = await client.getCatalog(catalogId);
            console.log(`Catalog name: ${catalog.name}`);
        }

        console.log('\nCreating a new catalog...');
        const newCatalog = await client.createCatalog({
            name: 'Test Catalog',
            description: 'Created from Node.js client with RSA256',
            type: 'products'
        });
        console.log(`Created catalog with ID: ${newCatalog.id}`);
        */

    } catch (error) {
        console.error(`Error: ${error.message}`);
    }

    // Example 5: Important notes
    console.log('\n' + '='.repeat(60));
    console.log('Important Notes:');
    console.log('- Server only needs your PUBLIC key to verify tokens');
    console.log('- Keep your PRIVATE key secure and never share it');
    console.log('- Use RS256 algorithm for enhanced security');
    console.log('- Tokens are now signed with asymmetric cryptography');
    console.log('='.repeat(60));
}

// Helper function to load keys from files (for production use)
function loadKeysFromFiles(privateKeyPath, publicKeyPath) {
    try {
        const privateKey = fs.readFileSync(privateKeyPath, 'utf8');
        const publicKey = publicKeyPath ? fs.readFileSync(publicKeyPath, 'utf8') : null;
        return { privateKey, publicKey };
    } catch (error) {
        console.error('Error loading keys:', error.message);
        return null;
    }
}

// Helper function to save keys to files
function saveKeysToFiles(privateKey, publicKey, privateKeyPath = 'private_key.pem', publicKeyPath = 'public_key.pem') {
    try {
        fs.writeFileSync(privateKeyPath, privateKey);
        fs.writeFileSync(publicKeyPath, publicKey);
        console.log(`Keys saved to ${privateKeyPath} and ${publicKeyPath}`);
        return true;
    } catch (error) {
        console.error('Error saving keys:', error.message);
        return false;
    }
}

// Export for use as module
module.exports = {
    GroupVANClient,
    generateRSAKeyPair,
    verifyJWT,
    loadKeysFromFiles,
    saveKeysToFiles
};

// Run example if executed directly
if (require.main === module) {
    main().catch(console.error);
}