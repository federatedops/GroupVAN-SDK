<?php

use PHPUnit\Framework\TestCase;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

require_once __DIR__ . '/../Client.php';

class ClientTest extends TestCase
{
    private $privateKey;
    private $publicKey;
    
    protected function setUp(): void
    {
        $keys = generateRSAKeyPair();
        $this->privateKey = $keys['privateKey'];
        $this->publicKey = $keys['publicKey'];
    }
    
    public function testGenerateRSAKeyPair()
    {
        $keys = generateRSAKeyPair();
        
        $this->assertNotEmpty($keys['privateKey']);
        $this->assertNotEmpty($keys['publicKey']);
        $this->assertStringContainsString('BEGIN PRIVATE KEY', $keys['privateKey']);
        $this->assertStringContainsString('END PRIVATE KEY', $keys['privateKey']);
        $this->assertStringContainsString('BEGIN PUBLIC KEY', $keys['publicKey']);
        $this->assertStringContainsString('END PUBLIC KEY', $keys['publicKey']);
    }
    
    public function testGenerateJWT()
    {
        $accessKey = [
            'developer_id' => 'test_dev_123',
            'key_id' => 'test_key_456',
            'private_key' => $this->privateKey
        ];
        
        $token = generateJWT($accessKey);
        
        $this->assertNotEmpty($token);
        $this->assertIsString($token);
        
        // Verify token structure (3 parts)
        $parts = explode('.', $token);
        $this->assertCount(3, $parts);
    }
    
    public function testJWTClaims()
    {
        $accessKey = [
            'developer_id' => 'test_dev_123',
            'key_id' => 'test_key_456',
            'private_key' => $this->privateKey
        ];
        
        $token = generateJWT($accessKey);
        $payload = json_decode(base64_decode(explode('.', $token)[1]), true);
        
        $this->assertEquals('groupvan', $payload['aud']);
        $this->assertEquals('test_dev_123', $payload['iss']);
        $this->assertEquals('test_key_456', $payload['kid']);
        $this->assertArrayHasKey('exp', $payload);
        $this->assertArrayHasKey('iat', $payload);
    }
    
    public function testJWTHeader()
    {
        $accessKey = [
            'developer_id' => 'test_dev_123',
            'key_id' => 'test_key_456',
            'private_key' => $this->privateKey
        ];
        
        $token = generateJWT($accessKey);
        $header = json_decode(base64_decode(explode('.', $token)[0]), true);
        
        $this->assertEquals('RS256', $header['alg']);
        $this->assertEquals('test_key_456', $header['kid']);
        $this->assertEquals('GV-JWT-V1', $header['gv-ver']);
    }
    
    public function testValidateJWT()
    {
        $accessKey = [
            'developer_id' => 'test_dev_123',
            'key_id' => 'test_key_456',
            'private_key' => $this->privateKey
        ];
        
        $token = generateJWT($accessKey);
        $result = validateJWT($token, $this->publicKey);
        
        $this->assertTrue($result['valid']);
        $this->assertEquals('test_dev_123', $result['payload']['iss']);
    }
    
    public function testValidateJWTWithWrongKey()
    {
        $accessKey = [
            'developer_id' => 'test_dev_123',
            'key_id' => 'test_key_456',
            'private_key' => $this->privateKey
        ];
        
        $token = generateJWT($accessKey);
        $wrongKeys = generateRSAKeyPair();
        $result = validateJWT($token, $wrongKeys['publicKey']);
        
        $this->assertFalse($result['valid']);
        $this->assertArrayHasKey('error', $result);
    }
    
    public function testGroupVANClient()
    {
        $client = new GroupVANClient(
            'test_dev_123',
            'test_key_456',
            $this->privateKey
        );
        
        $token = $client->generateJWT();
        
        $this->assertNotEmpty($token);
        $this->assertIsString($token);
        
        // Verify with public key
        $decoded = JWT::decode($token, new Key($this->publicKey, 'RS256'));
        $this->assertEquals('test_dev_123', $decoded->iss);
    }
    
    public function testClientMethods()
    {
        $client = new GroupVANClient(
            'test_dev_123',
            'test_key_456',
            $this->privateKey
        );
        
        $this->assertTrue(method_exists($client, 'generateJWT'));
        $this->assertTrue(method_exists($client, 'makeAuthenticatedRequest'));
        $this->assertTrue(method_exists($client, 'getCatalog'));
        $this->assertTrue(method_exists($client, 'listCatalogs'));
        $this->assertTrue(method_exists($client, 'createCatalog'));
    }
}
