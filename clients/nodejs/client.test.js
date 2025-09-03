/**
 * Tests for GroupVAN API Client
 */

const { GroupVANClient, generateRSAKeyPair } = require('./client');
const jwt = require('jsonwebtoken');

describe('GroupVAN API Client', () => {
  let client;
  let privateKey;
  let publicKey;

  beforeAll(() => {
    const keys = generateRSAKeyPair();
    privateKey = keys.privateKey;
    publicKey = keys.publicKey;

    client = new GroupVANClient(
      'test_developer_id',
      'test_key_id',
      privateKey,
    );
  });

  describe('RSA Key Generation', () => {
    test('should generate valid RSA key pair', () => {
      const keys = generateRSAKeyPair();

      expect(keys).toHaveProperty('privateKey');
      expect(keys).toHaveProperty('publicKey');
      expect(keys.privateKey).toContain('BEGIN PRIVATE KEY');
      expect(keys.privateKey).toContain('END PRIVATE KEY');
      expect(keys.publicKey).toContain('BEGIN PUBLIC KEY');
      expect(keys.publicKey).toContain('END PUBLIC KEY');
    });
  });

  describe('JWT Generation', () => {
    test('should generate a valid JWT', () => {
      const token = client.generateJWT();

      expect(token).toBeTruthy();
      expect(typeof token).toBe('string');
      expect(token.split('.')).toHaveLength(3);
    });

    test('should include correct claims', () => {
      const token = client.generateJWT();
      const decoded = jwt.decode(token);

      expect(decoded.aud).toBe('groupvan');
      expect(decoded.iss).toBe('test_developer_id');
      expect(decoded.kid).toBe('test_key_id');
      expect(decoded.exp).toBeGreaterThan(decoded.iat);
      expect(decoded.exp - decoded.iat).toBe(300);
    });

    test('should include correct header', () => {
      const token = client.generateJWT();
      const decoded = jwt.decode(token, { complete: true });

      expect(decoded.header.alg).toBe('RS256');
      expect(decoded.header.kid).toBe('test_key_id');
      expect(decoded.header['gv-ver']).toBe('GV-JWT-V1');
    });

    test('should allow custom expiry', () => {
      const token = client.generateJWT(600);
      const decoded = jwt.decode(token);

      expect(decoded.exp - decoded.iat).toBe(600);
    });

    test('should be verifiable with public key', () => {
      const token = client.generateJWT();

      const decoded = jwt.verify(token, publicKey, {
        algorithms: ['RS256'],
        audience: 'groupvan',
        issuer: 'test_developer_id',
      });

      expect(decoded).toBeTruthy();
      expect(decoded.aud).toBe('groupvan');
    });
  });

  describe('Client Methods', () => {
    test('should have makeAuthenticatedRequest method', () => {
      expect(typeof client.makeAuthenticatedRequest).toBe('function');
    });

    test('should have getCatalog method', () => {
      expect(typeof client.getCatalog).toBe('function');
    });

    test('should have listCatalogs method', () => {
      expect(typeof client.listCatalogs).toBe('function');
    });

    test('should have createCatalog method', () => {
      expect(typeof client.createCatalog).toBe('function');
    });
  });
});
