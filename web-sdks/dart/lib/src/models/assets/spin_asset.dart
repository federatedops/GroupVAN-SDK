class SpinAsset {
  const SpinAsset({
    required this.spinFrames,
    required this.spinPlanes,
    required this.spinUrl,
  });

  final int spinFrames;
  final int spinPlanes;
  final String? spinUrl;

  factory SpinAsset.fromJson(Map<String, dynamic> json) {
    return SpinAsset(
      spinFrames: json['spin_frames'] is int
          ? json['spin_frames']
          : int.tryParse(json['spin_frames']?.toString() ?? '24') ?? 24,
      spinPlanes: json['spin_planes'] is int
          ? json['spin_planes']
          : int.tryParse(json['spin_planes']?.toString() ?? '1') ?? 1,
      spinUrl: json['spin_url']?.toString(),
    );
  }
}

class SpinAssetResponse {
  const SpinAssetResponse({
    required this.hasSpinAssets,
    required this.spinAssets,
    required this.legacySpinFrames,
  });

  final bool hasSpinAssets;
  final List<SpinAsset> spinAssets;
  final int? legacySpinFrames;

  factory SpinAssetResponse.fromProductInfo(Map<String, dynamic> productInfo) {
    List<SpinAsset> spinAssets = [];
    int? legacySpinFrames;

    // Check for modern spin_assets format
    if (productInfo.containsKey('spin_assets')) {
      final spinAssetsData = productInfo['spin_assets'];
      if (spinAssetsData is List && spinAssetsData.isNotEmpty) {
        for (var assetData in spinAssetsData) {
          if (assetData is Map<String, dynamic>) {
            spinAssets.add(SpinAsset.fromJson(assetData));
          }
        }
      }
    }

    // Check for legacy spinFrames field
    if (productInfo.containsKey('spinFrames')) {
      final frames = productInfo['spinFrames'];
      if (frames != null) {
        legacySpinFrames = frames is int
            ? frames
            : int.tryParse(frames.toString());
      }
    }

    return SpinAssetResponse(
      hasSpinAssets: spinAssets.isNotEmpty || legacySpinFrames != null,
      spinAssets: spinAssets,
      legacySpinFrames: legacySpinFrames,
    );
  }
}
