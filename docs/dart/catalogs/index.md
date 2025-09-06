---
layout: default
title: Catalogs API
parent: Flutter/Dart SDK
nav_order: 4
has_children: true
permalink: /dart/catalogs/
description: "Complete catalogs API reference for the GroupVAN Flutter/Dart SDK with all endpoints for browsing catalogs, managing products, and cart operations."
---

# Catalogs API
{: .no_toc }

The Catalogs API provides comprehensive catalog browsing and product management capabilities including catalog listings, vehicle and supply categories, application assets, and cart management. The Dart SDK provides **complete 100% parity** with all Python API endpoints.

{: .fs-6 .fw-300 }

---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Quick Start

```dart
import 'package:groupvan/groupvan.dart';

void main() async {
  await GroupVAN.initialize(isProduction: false);
  
  // Authenticate first
  await GroupVAN.instance.auth.signInWithPassword(
    username: 'your-username',
    password: 'your-password',
    developerId: 'your-developer-id',
  );

  // Access catalogs API
  final catalogs = GroupVAN.instance.client.catalogs;
  
  // Get available catalogs
  final result = await catalogs.getCatalogs();
  result.fold(
    (error) => print('Error: $error'),
    (catalogList) => print('Found ${catalogList.length} catalogs'),
  );
}
```

---

## API Coverage

The Dart SDK provides complete coverage of all Catalogs API endpoints:

| **Endpoint** | **Method** | **Description** |
|:-------------|:-----------|:----------------|
| `GET /catalogs` | `getCatalogs()` | Get available catalogs |
| `GET /catalogs/{id}/vehicle-categories` | `getVehicleCategories()` | Get vehicle categories for catalog |
| `GET /catalogs/{id}/supply-categories` | `getSupplyCategories()` | Get supply categories for catalog |
| `GET /catalogs/{id}/application-assets` | `getApplicationAssets()` | Get application assets for catalog |
| `GET /catalogs/cart` | `getCart()` | Get cart contents |
| `GET /catalogs/{id}/products` | `getProducts()` | Get product listings with filtering |

---

## Core Methods

### Get Catalogs

Get all available catalogs for the authenticated user:

```dart
Future<Result<List<Catalog>>> getCatalogs()
```

**Example:**
```dart
final result = await GroupVAN.instance.client.catalogs.getCatalogs();
result.fold(
  (error) => print('Failed to get catalogs: $error'),
  (catalogs) {
    print('Available catalogs:');
    for (final catalog in catalogs) {
      print('• ${catalog.name} (ID: ${catalog.id})');
      if (catalog.description != null) {
        print('  ${catalog.description}');
      }
    }
  },
);
```

### Get Vehicle Categories

Get vehicle categories for a specific catalog:

```dart
Future<Result<List<VehicleCategory>>> getVehicleCategories({
  required String catalogId,
})
```

**Parameters:**
- `catalogId` - The ID of the catalog

**Example:**
```dart
final result = await GroupVAN.instance.client.catalogs.getVehicleCategories(
  catalogId: '123',
);

result.fold(
  (error) => print('Failed to get vehicle categories: $error'),
  (categories) {
    print('Vehicle categories:');
    for (final category in categories) {
      print('• ${category.name}');
      if (category.vehicleCount != null) {
        print('  Vehicles: ${category.vehicleCount}');
      }
    }
  },
);
```

### Get Supply Categories

Get supply categories for a specific catalog:

```dart
Future<Result<List<SupplyCategory>>> getSupplyCategories({
  required String catalogId,
})
```

**Parameters:**
- `catalogId` - The ID of the catalog

**Example:**
```dart
final result = await GroupVAN.instance.client.catalogs.getSupplyCategories(
  catalogId: '123',
);

result.fold(
  (error) => print('Failed to get supply categories: $error'),
  (categories) {
    print('Supply categories:');
    for (final category in categories) {
      print('• ${category.name}');
      if (category.productCount != null) {
        print('  Products: ${category.productCount}');
      }
    }
  },
);
```

---

## Advanced Methods

### Get Application Assets

Get application-specific assets for a catalog:

```dart
Future<Result<ApplicationAssets>> getApplicationAssets({
  required String catalogId,
})
```

**Example:**
```dart
final result = await GroupVAN.instance.client.catalogs.getApplicationAssets(
  catalogId: '123',
);

result.fold(
  (error) => print('Failed to get application assets: $error'),
  (assets) {
    print('Application assets:');
    if (assets.logoUrl != null) {
      print('• Logo: ${assets.logoUrl}');
    }
    if (assets.bannerUrl != null) {
      print('• Banner: ${assets.bannerUrl}');
    }
    if (assets.stylesheetUrl != null) {
      print('• Stylesheet: ${assets.stylesheetUrl}');
    }
  },
);
```

### Get Cart Contents

Get the current cart contents for the authenticated user:

```dart
Future<Result<Cart>> getCart()
```

**Example:**
```dart
final result = await GroupVAN.instance.client.catalogs.getCart();

result.fold(
  (error) => print('Failed to get cart: $error'),
  (cart) {
    print('Cart contents:');
    print('• Items: ${cart.itemCount}');
    print('• Total: \$${cart.totalAmount}');
    
    for (final item in cart.items) {
      print('• ${item.productName} (Qty: ${item.quantity}) - \$${item.price}');
    }
  },
);
```

### Get Products

Get product listings with optional filtering:

```dart
Future<Result<ProductListResponse>> getProducts({
  required String catalogId,
  String? categoryId,
  String? searchQuery,
  int page = 1,
  int limit = 20,
})
```

**Parameters:**
- `catalogId` - The ID of the catalog
- `categoryId` - Optional category filter
- `searchQuery` - Optional search term
- `page` - Page number for pagination (default: 1)
- `limit` - Number of products per page (default: 20, max: 100)

**Example:**
```dart
final result = await GroupVAN.instance.client.catalogs.getProducts(
  catalogId: '123',
  categoryId: 'automotive-parts',
  searchQuery: 'brake pads',
  page: 1,
  limit: 10,
);

result.fold(
  (error) => print('Failed to get products: $error'),
  (productResponse) {
    print('Products (Page ${productResponse.page}):');
    print('Total: ${productResponse.totalCount} products');
    
    for (final product in productResponse.products) {
      print('• ${product.name} - \$${product.price}');
      if (product.description != null) {
        print('  ${product.description}');
      }
      if (product.imageUrl != null) {
        print('  Image: ${product.imageUrl}');
      }
    }
    
    // Check if there are more pages
    final totalPages = (productResponse.totalCount / 10).ceil();
    if (productResponse.page < totalPages) {
      print('More pages available (${totalPages} total)');
    }
  },
);
```

---

## Data Models

### Catalog

```dart
class Catalog {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final DateTime? createdAt;
}
```

### VehicleCategory

```dart
class VehicleCategory {
  final String id;
  final String name;
  final String? description;
  final int? vehicleCount;
  final String? iconUrl;
}
```

### SupplyCategory

```dart
class SupplyCategory {
  final String id;
  final String name;
  final String? description;
  final int? productCount;
  final String? iconUrl;
}
```

### ApplicationAssets

```dart
class ApplicationAssets {
  final String? logoUrl;
  final String? bannerUrl;
  final String? stylesheetUrl;
  final String? faviconUrl;
  final Map<String, String>? customAssets;
}
```

### Cart

```dart
class Cart {
  final String id;
  final List<CartItem> items;
  final int itemCount;
  final double totalAmount;
  final DateTime updatedAt;
}
```

### CartItem

```dart
class CartItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double totalPrice;
  final String? imageUrl;
}
```

### Product

```dart
class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? categoryId;
  final bool isAvailable;
  final Map<String, dynamic>? attributes;
}
```

### ProductListResponse

```dart
class ProductListResponse {
  final List<Product> products;
  final int totalCount;
  final int page;
  final int limit;
}
```

---

## Error Handling

All methods return `Result<T>` types for safe error handling:

```dart
final result = await GroupVAN.instance.client.catalogs.getCatalogs();

result.fold(
  (error) {
    if (error is NetworkException) {
      print('Network error: ${error.message}');
      // Show retry option
    } else if (error is ValidationException) {
      print('Validation error: ${error.errors}');
      // Show field-specific errors
    } else if (error is AuthenticationException) {
      print('Auth error: ${error.message}');
      // Redirect to login
    } else {
      print('Unknown error: $error');
    }
  },
  (catalogs) {
    // Handle success
    print('Loaded ${catalogs.length} catalogs');
  },
);
```

---

## Complete Example

Here's a complete example showing catalog browsing with product search:

```dart
import 'package:flutter/material.dart';
import 'package:groupvan/groupvan.dart';

class CatalogBrowserExample extends StatefulWidget {
  @override
  _CatalogBrowserExampleState createState() => _CatalogBrowserExampleState();
}

class _CatalogBrowserExampleState extends State<CatalogBrowserExample> {
  List<Catalog> _catalogs = [];
  List<Product> _products = [];
  String? _selectedCatalogId;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    setState(() => _isLoading = true);

    final result = await GroupVAN.instance.client.catalogs.getCatalogs();
    result.fold(
      (error) => _showError('Failed to load catalogs: $error'),
      (catalogs) {
        setState(() {
          _catalogs = catalogs;
          if (catalogs.isNotEmpty) {
            _selectedCatalogId = catalogs.first.id;
            _loadProducts();
          }
        });
      },
    );

    setState(() => _isLoading = false);
  }

  Future<void> _loadProducts() async {
    if (_selectedCatalogId == null) return;

    setState(() => _isLoading = true);

    final result = await GroupVAN.instance.client.catalogs.getProducts(
      catalogId: _selectedCatalogId!,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      limit: 20,
    );

    result.fold(
      (error) => _showError('Failed to load products: $error'),
      (productResponse) {
        setState(() => _products = productResponse.products);
        _showSuccess('Found ${productResponse.totalCount} products');
      },
    );

    setState(() => _isLoading = false);
  }

  Future<void> _loadCart() async {
    final result = await GroupVAN.instance.client.catalogs.getCart();
    result.fold(
      (error) => _showError('Failed to load cart: $error'),
      (cart) => _showCartDialog(cart),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showCartDialog(Cart cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Shopping Cart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items: ${cart.itemCount}'),
            Text('Total: \$${cart.totalAmount.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            ...cart.items.map((item) => ListTile(
              title: Text(item.productName),
              subtitle: Text('Qty: ${item.quantity}'),
              trailing: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catalog Browser'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: _loadCart,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCatalogSelector(),
          _buildSearchBar(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildCatalogSelector() {
    if (_catalogs.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        value: _selectedCatalogId,
        decoration: InputDecoration(labelText: 'Select Catalog'),
        items: _catalogs.map((catalog) => DropdownMenuItem(
          value: catalog.id,
          child: Text(catalog.name),
        )).toList(),
        onChanged: (catalogId) {
          setState(() {
            _selectedCatalogId = catalogId;
            _products.clear();
          });
          if (catalogId != null) {
            _loadProducts();
          }
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Search products...',
          suffixIcon: Icon(Icons.search),
        ),
        onChanged: (query) {
          setState(() => _searchQuery = query);
        },
        onSubmitted: (_) => _loadProducts(),
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No products found'),
            if (_selectedCatalogId != null) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProducts,
                child: Text('Reload'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image_not_supported),
                  )
                : Icon(Icons.shopping_bag),
            title: Text(product.name),
            subtitle: product.description != null 
                ? Text(
                    product.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ) 
                : null,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!product.isAvailable)
                  Text(
                    'Out of Stock',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
            onTap: () => _showProductDetails(product),
          ),
        );
      },
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imageUrl != null) ...[
              Image.network(product.imageUrl!, height: 200),
              SizedBox(height: 16),
            ],
            if (product.description != null) ...[
              Text(product.description!),
              SizedBox(height: 16),
            ],
            Text('Price: \$${product.price.toStringAsFixed(2)}'),
            Text('Available: ${product.isAvailable ? 'Yes' : 'No'}'),
            if (product.attributes != null) ...[
              SizedBox(height: 16),
              Text('Attributes:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...product.attributes!.entries.map((entry) => 
                Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          if (product.isAvailable)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccess('Added ${product.name} to cart');
              },
              child: Text('Add to Cart'),
            ),
        ],
      ),
    );
  }
}
```

---

## Next Steps

- **[Vehicles API](../vehicles/)** - Vehicle management and search
- **[Authentication](../authentication)** - Advanced authentication patterns
- **[Error Handling](../error-handling)** - Comprehensive error handling
- **[Logging](../logging)** - Debugging and monitoring