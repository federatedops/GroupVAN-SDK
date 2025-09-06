---
layout: default
title: PHP
nav_order: 6
has_children: true
---

# PHP Client Library
{: .no_toc }

Complete documentation for the GroupVAN PHP client library.
{: .fs-6 .fw-300 }

---

## Installation

### Requirements
- PHP 7.4 or higher
- Composer package manager

### Install via Composer

```bash
composer require groupvan/client
```

## Quick Example

```php
<?php
require_once 'vendor/autoload.php';

use GroupVAN\Client;

// Initialize client
$client = new Client([
    'developer_id' => 'DEV123',
    'key_id' => 'KEY001',
    'private_key_path' => '/path/to/private_key.pem'
]);

// Generate JWT token
$token = $client->generateToken();

// Make API call
$response = $client->apiCall('GET', '/api/v3/users', $token);

echo json_encode($response);
```

## Configuration

```php
// Using array configuration
$client = new Client([
    'developer_id' => 'DEV123',
    'key_id' => 'KEY001',
    'private_key_path' => '/path/to/private_key.pem',
    'base_url' => 'https://api.groupvan.com', // optional
    'timeout' => 30 // optional, in seconds
]);

// Using environment variables
$client = Client::fromEnv();
// Looks for:
// - GROUPVAN_DEVELOPER_ID
// - GROUPVAN_KEY_ID
// - GROUPVAN_PRIVATE_KEY_PATH
```

## API Reference

### Methods

#### generateToken($options = [])
Generate a JWT token for API authentication.

```php
$token = $client->generateToken([
    'expiration_minutes' => 5, // optional, default: 5
    'additional_claims' => [] // optional
]);
```

#### apiCall($method, $endpoint, $token = null, $options = [])
Make an authenticated API call.

```php
$response = $client->apiCall(
    'POST',
    '/api/v3/users',
    $token,
    [
        'data' => ['name' => 'John Doe'],
        'params' => ['page' => 1],
        'headers' => ['X-Custom' => 'value']
    ]
);
```

## Error Handling

```php
try {
    $token = $client->generateToken();
    $response = $client->apiCall('GET', '/api/v3/users', $token);
} catch (\GroupVAN\AuthenticationException $e) {
    echo "Authentication failed: " . $e->getMessage();
} catch (\GroupVAN\APIException $e) {
    echo "API call failed: " . $e->getMessage();
    echo "Status code: " . $e->getStatusCode();
}
```

## Resources

- [Source Code](https://github.com/federatedops/GroupVAN-SDK/tree/main/clients/php)
- [Packagist Package](https://packagist.org/packages/groupvan/client)
- [Examples](https://github.com/federatedops/GroupVAN-SDK/tree/main/examples/php)