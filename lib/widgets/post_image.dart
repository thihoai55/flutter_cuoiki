import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'post_image_io.dart'
  if (dart.library.html) 'post_image_web.dart'
  as platform_image;

class PostImage extends StatelessWidget {
  const PostImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  bool get _isLocalFile => platform_image.canLoadFile(url);
  bool get _isDataUri => url != null && url!.startsWith('data:image');

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _buildImage() {
    if (url == null || url!.isEmpty) {
      return _placeholder();
    }

    if (_isDataUri) {
      final bytes = _decodeDataUri(url!);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }

    if (_isLocalFile) {
      return platform_image.buildFileImage(
        url!,
        width: width,
        height: height,
        fit: fit,
        onError: _placeholder,
      );
    }

    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: placeholder ?? const Icon(Icons.image, color: Colors.grey),
    );
  }

  Uint8List? _decodeDataUri(String data) {
    final commaIndex = data.indexOf(',');
    if (commaIndex == -1) return null;
    try {
      return base64Decode(data.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}
