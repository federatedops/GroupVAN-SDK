#!/usr/bin/env python3
"""
Tests for GroupVAN API Client
"""

import unittest
from unittest.mock import patch, Mock
import jwt
import time
import math
from client import GroupVANClient, generate_rsa_key_pair


class TestGroupVANClient(unittest.TestCase):
    """Test cases for GroupVAN API Client"""

    def setUp(self):
        """Set up test fixtures"""
        self.private_key, self.public_key = generate_rsa_key_pair()
        self.client = GroupVANClient(
            developer_id="test_dev_123",
            key_id="test_key_456",
            private_key_pem=self.private_key,
        )

    def test_generate_rsa_key_pair(self):
        """Test RSA key pair generation"""
        private_key, public_key = generate_rsa_key_pair()
        
        # Check that keys are generated
        self.assertIsNotNone(private_key)
        self.assertIsNotNone(public_key)
        
        # Check key format
        self.assertIn("BEGIN PRIVATE KEY", private_key)
        self.assertIn("END PRIVATE KEY", private_key)
        self.assertIn("BEGIN PUBLIC KEY", public_key)
        self.assertIn("END PUBLIC KEY", public_key)

    def test_generate_jwt(self):
        """Test JWT generation"""
        token = self.client.generate_jwt()
        
        # Check that token is generated
        self.assertIsNotNone(token)
        self.assertIsInstance(token, str)
        
        # Decode and verify token structure
        decoded = jwt.decode(token, options={"verify_signature": False})
        
        # Check required claims
        self.assertEqual(decoded["aud"], "groupvan")
        self.assertEqual(decoded["iss"], "test_dev_123")
        self.assertEqual(decoded["kid"], "test_key_456")
        self.assertIn("exp", decoded)
        self.assertIn("iat", decoded)
        
        # Check expiration (should be ~5 minutes from now)
        current_time = math.floor(time.time())
        self.assertGreater(decoded["exp"], current_time)
        self.assertLessEqual(decoded["exp"], current_time + 310)  # 5 min + buffer

    def test_jwt_verification(self):
        """Test that generated JWT can be verified with public key"""
        token = self.client.generate_jwt()
        
        # Verify token with public key
        try:
            verified_payload = jwt.decode(
                token,
                self.public_key,
                algorithms=["RS256"],
                audience="groupvan",
            )
            # If we get here, verification succeeded
            self.assertIsNotNone(verified_payload)
            self.assertEqual(verified_payload["iss"], "test_dev_123")
        except jwt.InvalidTokenError:
            self.fail("Token verification failed")

    def test_jwt_header(self):
        """Test JWT header contains correct information"""
        token = self.client.generate_jwt()
        header = jwt.get_unverified_header(token)
        
        self.assertEqual(header["alg"], "RS256")
        self.assertEqual(header["kid"], "test_key_456")
        self.assertEqual(header["gv-ver"], "GV-JWT-V1")

    @patch("requests.request")
    def test_make_authenticated_request(self, mock_request):
        """Test making authenticated requests"""
        # Setup mock response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"id": "catalog_123", "name": "Test Catalog"}
        mock_request.return_value = mock_response
        
        # Make request
        response = self.client.make_authenticated_request(
            method="GET",
            endpoint="/catalogs/123",
        )
        
        # Check request was made correctly
        mock_request.assert_called_once()
        call_args = mock_request.call_args
        
        # Check method and URL
        self.assertEqual(call_args.kwargs["method"], "GET")
        self.assertEqual(call_args.kwargs["url"], "https://api.groupvan.com/v3/catalogs/123")
        
        # Check authorization header
        headers = call_args.kwargs["headers"]
        self.assertIn("Authorization", headers)
        self.assertTrue(headers["Authorization"].startswith("Bearer "))
        self.assertEqual(headers["Content-Type"], "application/json")

    @patch("requests.request")
    def test_get_catalog(self, mock_request):
        """Test get_catalog method"""
        # Setup mock response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"id": "catalog_123", "name": "Test Catalog"}
        mock_request.return_value = mock_response
        
        # Get catalog
        result = self.client.get_catalog("catalog_123")
        
        # Check result
        self.assertEqual(result["id"], "catalog_123")
        self.assertEqual(result["name"], "Test Catalog")

    @patch("requests.request")
    def test_get_catalog_error(self, mock_request):
        """Test get_catalog error handling"""
        # Setup mock error response
        mock_response = Mock()
        mock_response.status_code = 404
        mock_response.text = "Catalog not found"
        mock_request.return_value = mock_response
        
        # Check that exception is raised
        with self.assertRaises(Exception) as context:
            self.client.get_catalog("invalid_catalog")
        
        self.assertIn("Failed to get catalog", str(context.exception))
        self.assertIn("404", str(context.exception))

    @patch("requests.request")
    def test_list_catalogs(self, mock_request):
        """Test list_catalogs method"""
        # Setup mock response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "items": [
                {"id": "catalog_1", "name": "Catalog 1"},
                {"id": "catalog_2", "name": "Catalog 2"},
            ],
            "total": 2,
        }
        mock_request.return_value = mock_response
        
        # List catalogs
        result = self.client.list_catalogs(limit=10, offset=0)
        
        # Check result
        self.assertEqual(len(result["items"]), 2)
        self.assertEqual(result["total"], 2)
        
        # Check request parameters
        call_args = mock_request.call_args
        self.assertEqual(call_args.kwargs["params"]["limit"], 10)
        self.assertEqual(call_args.kwargs["params"]["offset"], 0)

    def test_custom_expiration(self):
        """Test JWT generation with custom expiration"""
        # Generate token with 10 minute expiration
        token = self.client.generate_jwt(expires_in=600)
        decoded = jwt.decode(token, options={"verify_signature": False})
        
        current_time = math.floor(time.time())
        # Check expiration is ~10 minutes from now
        self.assertGreater(decoded["exp"], current_time + 590)
        self.assertLessEqual(decoded["exp"], current_time + 610)

    def test_rsa_key_size(self):
        """Test RSA key generation with different key sizes"""
        # Test 2048-bit key (default)
        private_2048, public_2048 = generate_rsa_key_pair(2048)
        self.assertIsNotNone(private_2048)
        self.assertIsNotNone(public_2048)
        
        # Test 4096-bit key
        private_4096, public_4096 = generate_rsa_key_pair(4096)
        self.assertIsNotNone(private_4096)
        self.assertIsNotNone(public_4096)
        
        # 4096-bit keys should be longer
        self.assertGreater(len(private_4096), len(private_2048))


if __name__ == "__main__":
    unittest.main()