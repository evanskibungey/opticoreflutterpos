import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';

class NetworkImageHelper extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String productName;
  final BorderRadius? borderRadius;
  final Color backgroundColor;

  const NetworkImageHelper({
    Key? key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = 150,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.productName = '',
    this.borderRadius,
    this.backgroundColor = const Color(0xFFF5F5F5),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check for null or empty URL
    if (imageUrl == null || imageUrl!.isEmpty) {
      if (ApiConfig.enableDebugLogs) {
        debugPrint('🖼️ Image URL is null or empty for product: $productName');
      }
      return _buildFallback();
    }

    // Log the image URL for debugging
    if (ApiConfig.enableDebugLogs) {
      debugPrint('🖼️ Loading image for $productName: $imageUrl');
    }

    // Container for consistent styling
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) {
          if (ApiConfig.enableDebugLogs) {
            debugPrint('🖼️ Error loading image for $productName: $error');
            debugPrint('   URL: $url');
          }
          return errorWidget ?? _buildDefaultError();
        },
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey.shade400,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            productName.isNotEmpty 
                ? productName 
                : 'Image not available',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: Colors.grey.shade400,
              size: 32,
            ),
            if (productName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  productName,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}