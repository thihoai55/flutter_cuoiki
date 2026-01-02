import 'dart:io';
import 'package:flutter/material.dart';

bool canLoadFile(String? path) {
  if (path == null) return false;
  return File(path).existsSync();
}

Widget buildFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit? fit,
  Widget Function()? onError,
}) {
  try {
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          onError != null ? onError() : const SizedBox(),
    );
  } catch (e) {
    return onError != null ? onError() : const SizedBox();
  }
}
