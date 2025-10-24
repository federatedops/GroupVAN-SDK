import '../product_info/product_info_response.dart';

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
  });

  final bool hasSpinAssets;
  final List<SpinAsset> spinAssets;

  factory SpinAssetResponse.fromProductInfo(ProductInfoResponse productInfo) {
    List<SpinAsset> spinAssets = productInfo.spinAssets ?? [];
    return SpinAssetResponse(
      hasSpinAssets: spinAssets.isNotEmpty,
      spinAssets: spinAssets,
    );
  }
}
