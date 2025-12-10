library groupvan;

// Main SDK Interface - Only singleton pattern allowed
export 'src/client.dart'
    show
        GroupVAN,
        GroupVANClient,
        GroupVANAuth,
        GroupVANVehicles,
        GroupVANCatalogs,
        GroupVANSearch,
        AuthUser,
        AuthSession,
        AuthChangeEvent,
        AuthState;

// Token storage (for custom implementations)
export 'src/auth/auth_manager.dart'
    show TokenStorage, SecureTokenStorage, MemoryTokenStorage;

// Session management
export 'src/session/session_cubit.dart' show SessionCubit;

// Essential types and exceptions for error handling
export 'src/core/exceptions.dart';
export 'src/core/response.dart' show Result;

// Public models that developers need
export 'src/models/models.dart'
    show
        Vehicle,
        VehicleGroup,
        VehicleSearchResponse,
        VehicleCategory,
        Catalog,
        CatalogType,
        SupplyCategory,
        SupplySubcategory,
        TopCategory,
        ApplicationAsset,
        ApplicationAssetsRequest,
        DisplayTier,
        PartType,
        PartTypeRequest,
        ProductListingRequest,
        ProductListing,
        Part,
        PartApplication,
        PartApplicationDisplay,
        Brand,
        Attribute,
        AttributeFamily,
        VehicleFilterRequest,
        VehicleFilterResponse,
        VehicleFilterOption,
        Fleet,
        EngineSearchRequest,
        VehicleSearchRequest,
        VinSearchRequest,
        PlateSearchRequest,
        User,
        Asset,
        SpinAsset,
        SpinAssetResponse,
        ItemPricing,
        ItemPricingLocation,
        ItemPricingRequest,
        Interchange,
        InterchangeBrand,
        InterchangePartType,
        InterchangePart,
        ProductInfoResponse,
        InfoAttribute,
        Document,
        OmniSearchResponse,
        MemberCategory,
        AddToCartRequest,
        RemoveFromCartRequest,
        CartResponse,
        CartItem,
        CartItemType,
        RemovalItem;
