#!/usr/bin/env python3
"""
Example Client Implementation for JWT Authentication

This script demonstrates how clients can generate JWTs and make authenticated
requests to V3 APIs using RSA256 JWT authentication.
"""

import jwt
import time
import math
import requests
import json
from typing import Dict, Any
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend


class GroupVANClient:
    """Example client for authenticated V3 API requests using RSA256."""
    
    def __init__(self, developer_id: str, key_id: str, private_key_pem: str):
        """
        Initialize the client with developer credentials.
        
        Args:
            developer_id: Your developer ID
            key_id: Your key ID
            private_key_pem: Your RSA private key in PEM format
        """
        self.developer_id = developer_id
        self.key_id = key_id
        self.private_key_pem = private_key_pem
        self.base_url = "https://api.groupvan.com/v3"  # Replace with actual URL
    
    def generate_jwt(self, expires_in: int = 300) -> str:
        """
        Generate a JWT token for authentication using RSA256.
        
        Args:
            expires_in: Token expiry in seconds (default 5 minutes)
        
        Returns:
            Signed JWT token
        """
        current_time = math.floor(time.time())
        
        # Create JWT claims
        claims = {
            "aud": "groupvan",
            "iss": self.developer_id,
            "kid": self.key_id,
            "exp": current_time + expires_in,
            "iat": current_time
        }
        
        # Generate JWT with RSA256 algorithm
        token = jwt.encode(
            claims,
            self.private_key_pem,
            algorithm="RS256",
            headers={"gv-ver": "GV-JWT-V1", "kid": self.key_id}
        )
        
        return token
    
    def make_authenticated_request(
        self,
        method: str,
        endpoint: str,
        data: Dict[str, Any] = None,
        params: Dict[str, Any] = None
    ) -> requests.Response:
        """
        Make an authenticated request to the V3 API.
        
        Args:
            method: HTTP method (GET, POST, etc.)
            endpoint: API endpoint path
            data: Request body data (for POST/PUT)
            params: Query parameters
        
        Returns:
            Response object
        """
        # Generate fresh JWT token
        token = self.generate_jwt()
        
        # Prepare headers
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Construct full URL
        url = f"{self.base_url}{endpoint}"
        
        # Make request
        response = requests.request(
            method=method,
            url=url,
            headers=headers,
            json=data,
            params=params
        )
        
        return response
    
    def get_catalog(self, catalog_id: str) -> Dict[str, Any]:
        """
        Example: Get a catalog by ID.
        
        Args:
            catalog_id: The catalog ID
        
        Returns:
            Catalog data
        """
        response = self.make_authenticated_request(
            method="GET",
            endpoint=f"/catalogs/{catalog_id}"
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"Failed to get catalog: {response.status_code} - {response.text}")
    
    def list_catalogs(self, limit: int = 10, offset: int = 0) -> Dict[str, Any]:
        """
        Example: List available catalogs.
        
        Args:
            limit: Number of results to return
            offset: Pagination offset
        
        Returns:
            List of catalogs
        """
        response = self.make_authenticated_request(
            method="GET",
            endpoint="/catalogs",
            params={"limit": limit, "offset": offset}
        )
        
        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"Failed to list catalogs: {response.status_code} - {response.text}")


def generate_rsa_key_pair(key_size: int = 2048) -> tuple[str, str]:
    """
    Generate a new RSA key pair for JWT signing.
    
    Args:
        key_size: Size of the RSA key in bits (default 2048)
    
    Returns:
        Tuple of (private_key_pem, public_key_pem) as strings
    """
    # Generate private key
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=key_size,
        backend=default_backend()
    )
    
    # Export private key to PEM format
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    ).decode('utf-8')
    
    # Get public key
    public_key = private_key.public_key()
    
    # Export public key to PEM format
    public_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode('utf-8')
    
    return private_pem, public_pem


def main():
    """Example usage of the GroupVAN client with RSA256."""
    
    print("=" * 60)
    print("GroupVAN JWT Authentication Example (RSA256)")
    print("=" * 60)
    
    # Generate RSA key pair for demo
    print("\n1. Generating RSA key pair...")
    private_key_pem, public_key_pem = generate_rsa_key_pair()
    
    print("Private Key (keep this secret!):")
    print(private_key_pem[:200] + "...")
    print("\nPublic Key (share with server):")
    print(public_key_pem[:200] + "...")
    
    # Example credentials (replace with your actual credentials)
    # In production, load private key from secure storage
    DEVELOPER_ID = "dev_abc123"
    KEY_ID = "key_xyz789"
    
    # Initialize client with RSA private key
    client = GroupVANClient(
        developer_id=DEVELOPER_ID,
        key_id=KEY_ID,
        private_key_pem=private_key_pem
    )
    
    try:
        # Example 2: Generate a JWT token
        print("\n2. Generating JWT token with RSA256...")
        token = client.generate_jwt()
        print(f"Token: {token[:50]}...")  # Show first 50 chars
        
        # Decode token to show claims (for debugging)
        decoded = jwt.decode(token, options={"verify_signature": False})
        print(f"\nToken claims: {json.dumps(decoded, indent=2)}")
        
        # Decode header to show algorithm
        header = jwt.get_unverified_header(token)
        print(f"\nToken header: {json.dumps(header, indent=2)}")
        
        # Example 3: Verify token with public key (server-side operation)
        print("\n3. Verifying token with public key...")
        try:
            verified_payload = jwt.decode(
                token,
                public_key_pem,
                algorithms=["RS256"],
                audience="groupvan"
            )
            print("✓ Token verified successfully!")
            print(f"Verified payload: {json.dumps(verified_payload, indent=2)}")
        except jwt.InvalidTokenError as e:
            print(f"✗ Token verification failed: {e}")
        
        # Example 4: API calls (uncomment when API is ready)
        """
        print("\n4. Making API calls...")
        catalogs = client.list_catalogs(limit=5)
        print(f"Found {len(catalogs.get('items', []))} catalogs")
        
        if catalogs.get('items'):
            catalog_id = catalogs['items'][0]['id']
            print(f"\nGetting catalog {catalog_id}...")
            catalog = client.get_catalog(catalog_id)
            print(f"Catalog name: {catalog.get('name')}")
        """
        
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    # Example of generating a JWT using RSA256
    
    print("=" * 60)
    print("GroupVAN JWT Authentication Example with RSA256")
    print("=" * 60)
    
    # Generate or load RSA keys
    # In production, load these from secure storage
    private_key_pem, public_key_pem = generate_rsa_key_pair()
    
    # Example credentials
    access_key = {
        "developer_id": "dev_abc123",
        "key_id": "key_xyz789",
        "private_key": private_key_pem  # RSA private key instead of shared secret
    }
    
    # Generate JWT token with RSA256
    token = jwt.encode(
        {
            "aud": "groupvan",
            "iss": access_key["developer_id"],
            "kid": access_key["key_id"],
            "exp": math.floor(time.time() + 300),
            "iat": math.floor(time.time()),
        },
        access_key["private_key"],
        algorithm="RS256",  # Changed from HS256 to RS256
        headers={"gv-ver": "GV-JWT-V1", "kid": access_key["key_id"]}
    )
    
    print(f"\nGenerated JWT Token (RSA256):")
    print(f"{token}")
    
    print(f"\nUse this token in your API requests:")
    print(f"Authorization: Bearer {token}")
    
    print("\n" + "=" * 60)
    print("Note: Server only needs your PUBLIC key to verify tokens")
    print("Keep your PRIVATE key secure and never share it!")
    print("=" * 60)
    
    # Run full example
    main()