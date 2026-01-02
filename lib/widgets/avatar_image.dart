import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as platform_io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Avatar image that accepts either a network URL or local file path.
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.url,
    this.size = 48,
    this.initials,
    this.backgroundColor,
    this.textStyle,
  });

  final String? url;
  final double size;
  final String? initials;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  bool get _isLocalFile => !kIsWeb && url != null && url!.isNotEmpty && !url!.startsWith('http') && !url!.startsWith('data:image');
  bool get _isDataUri => url != null && url!.startsWith('data:image');

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.blue.shade100;
    final text = textStyle ?? TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold);

    Widget child;
    if (url != null && url!.isNotEmpty) {
      if (_isDataUri) {
        final bytes = _decodeDataUri(url!);
        child = bytes != null
            ? Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _fallback(bg, text),
              )
            : _fallback(bg, text);
      } else if (_isLocalFile) {
        child = Image.file(
          platform_io.File(url!),
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _fallback(bg, text),
        );
      } else {
        child = Image.network(
          url!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _fallback(bg, text),
        );
      }
    } else {
      child = _fallback(bg, text);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }

  Widget _fallback(Color bg, TextStyle text) {
    final init = (initials != null && initials!.isNotEmpty) ? initials! : '?';
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(init, style: text.copyWith(fontSize: size * 0.45)),
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
