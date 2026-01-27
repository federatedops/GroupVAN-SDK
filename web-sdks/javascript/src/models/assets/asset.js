/**
 * Asset models
 */

/**
 * Asset image
 */
export class AssetImage {
  constructor({ primary, large, medium, thumb }) {
    this.primary = primary;
    this.large = large;
    this.medium = medium;
    this.thumb = thumb;
  }

  static fromJson(json) {
    return new AssetImage({
      primary: json.primary || false,
      large: json.large_path,
      medium: json.medium_path,
      thumb: json.thumb_path,
    });
  }
}

/**
 * Asset model
 */
export class Asset {
  constructor({ images, brandLogo, sku, spinAsset }) {
    this.images = images;
    this.brandLogo = brandLogo;
    this.sku = sku;
    this.spinAsset = spinAsset;
  }

  static fromJson(json) {
    return new Asset({
      images: (json.product_images || []).map(img => AssetImage.fromJson(img)),
      brandLogo: json.logo,
      sku: json.sku,
      spinAsset: json.spin_assets || false,
    });
  }
}

/**
 * Spin asset model for 360-degree images
 */
export class SpinAsset {
  constructor({ id, frames, baseUrl }) {
    this.id = id;
    this.frames = frames;
    this.baseUrl = baseUrl;
  }

  static fromJson(json) {
    return new SpinAsset({
      id: json.id,
      frames: json.frames || [],
      baseUrl: json.base_url,
    });
  }
}

/**
 * Spin asset response
 */
export class SpinAssetResponse {
  constructor({ spinAsset }) {
    this.spinAsset = spinAsset;
  }

  static fromJson(json) {
    return new SpinAssetResponse({
      spinAsset: json.spin_asset ? SpinAsset.fromJson(json.spin_asset) : null,
    });
  }
}
