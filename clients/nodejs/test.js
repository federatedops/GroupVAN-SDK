#!/usr/bin/env node
/**
 * Tests for GroupVAN API Client
 */

const assert = require('assert');
const { GroupVANClient, generateRSAKeyPair } = require('./client');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

describe('GroupVAN API Client', () => {
    let client;
    let privateKey;
    let publicKey;

    before(() => {
        const keys = generateRSAKeyPair();
        privateKey = keys.privateKey;
        publicKey = keys.publicKey;
        
        client = new GroupVANClient(
            'test_dev_123',
            'test_key_456',
            privateKey
        );
    });

    describe('generateRSAKeyPair', () => {
        it('should generate valid RSA key pair', () => {
            const keys = generateRSAKeyPair();
            
            assert(keys.privateKey);
            assert(keys.publicKey);
            assert(keys.privateKey.includes('BEGIN PRIVATE KEY'));
            assert(keys.privateKey.includes('END PRIVATE KEY'));
            assert(keys.publicKey.includes('BEGIN PUBLIC KEY'));
            assert(keys.publicKey.includes('END PUBLIC KEY'));
        });

        it('should generate different keys each time', () => {
            const keys1 = generateRSAKeyPair();
            const keys2 = generateRSAKeyPair();
            
            assert.notEqual(keys1.privateKey, keys2.privateKey);
            assert.notEqual(keys1.publicKey, keys2.publicKey);
        });
    });

    describe('generateJWT', () => {
        it('should generate a valid JWT token', () => {
            const token = client.generateJWT();
            
            assert(token);
            assert(typeof token === 'string');
            
            // Verify token structure (3 parts separated by dots)
            const parts = token.split('.');
            assert.equal(parts.length, 3);
        });

        it('should include correct claims', () => {
            const token = client.generateJWT();
            const decoded = jwt.decode(token);
            
            assert.equal(decoded.aud, 'groupvan');
            assert.equal(decoded.iss, 'test_dev_123');
            assert.equal(decoded.kid, 'test_key_456');
            assert(decoded.exp);
            assert(decoded.iat);
        });

        it('should set correct expiration time', () => {
            const token = client.generateJWT(600); // 10 minutes
            const decoded = jwt.decode(token);
            
            const now = Math.floor(Date.now() / 1000);
            assert(decoded.exp > now + 590);
            assert(decoded.exp <= now + 610);
        });

        it('should include correct header', () => {
            const token = client.generateJWT();
            const header = jwt.decode(token, { complete: true }).header;
            
            assert.equal(header.alg, 'RS256');
            assert.equal(header.kid, 'test_key_456');
            assert.equal(header['gv-ver'], 'GV-JWT-V1');
        });
    });

    describe('JWT Verification', () => {
        it('should verify token with public key', () => {
            const token = client.generateJWT();
            
            const verified = jwt.verify(token, publicKey, {
                algorithms: ['RS256'],
                audience: 'groupvan'
            });
            
            assert(verified);
            assert.equal(verified.iss, 'test_dev_123');
        });

        it('should fail verification with wrong public key', () => {
            const token = client.generateJWT();
            const wrongKeys = generateRSAKeyPair();
            
            assert.throws(() => {
                jwt.verify(token, wrongKeys.publicKey, {
                    algorithms: ['RS256'],
                    audience: 'groupvan'
                });
            });
        });

        it('should fail verification with wrong audience', () => {
            const token = client.generateJWT();
            
            assert.throws(() => {
                jwt.verify(token, publicKey, {
                    algorithms: ['RS256'],
                    audience: 'wrong_audience'
                });
            });
        });
    });

    describe('makeAuthenticatedRequest', () => {
        it('should create request with correct headers', async () => {
            // This would need mocking in a real test
            // For now, we just verify the method exists and can be called
            assert(typeof client.makeAuthenticatedRequest === 'function');
        });
    });

    describe('API methods', () => {
        it('should have getCatalog method', () => {
            assert(typeof client.getCatalog === 'function');
        });

        it('should have listCatalogs method', () => {
            assert(typeof client.listCatalogs === 'function');
        });
    });
});

// Run tests if executed directly
if (require.main === module) {
    console.log('Running GroupVAN API Client Tests...\n');
    
    let passed = 0;
    let failed = 0;
    
    // Simple test runner
    const tests = [
        {
            name: 'RSA Key Generation',
            test: () => {
                const keys = generateRSAKeyPair();
                assert(keys.privateKey && keys.publicKey);
            }
        },
        {
            name: 'JWT Generation',
            test: () => {
                const keys = generateRSAKeyPair();
                const client = new GroupVANClient('dev_123', 'key_456', keys.privateKey);
                const token = client.generateJWT();
                assert(token && token.split('.').length === 3);
            }
        },
        {
            name: 'JWT Verification',
            test: () => {
                const keys = generateRSAKeyPair();
                const client = new GroupVANClient('dev_123', 'key_456', keys.privateKey);
                const token = client.generateJWT();
                const verified = jwt.verify(token, keys.publicKey, {
                    algorithms: ['RS256'],
                    audience: 'groupvan'
                });
                assert(verified.iss === 'dev_123');
            }
        },
        {
            name: 'JWT Claims',
            test: () => {
                const keys = generateRSAKeyPair();
                const client = new GroupVANClient('dev_123', 'key_456', keys.privateKey);
                const token = client.generateJWT();
                const decoded = jwt.decode(token);
                assert(decoded.aud === 'groupvan');
                assert(decoded.kid === 'key_456');
            }
        }
    ];
    
    tests.forEach(({ name, test }) => {
        try {
            test();
            console.log(`✓ ${name}`);
            passed++;
        } catch (error) {
            console.log(`✗ ${name}: ${error.message}`);
            failed++;
        }
    });
    
    console.log(`\n${passed} passed, ${failed} failed`);
    process.exit(failed > 0 ? 1 : 0);
}