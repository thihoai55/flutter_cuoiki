import 'package:flutter/material.dart';

bool canLoadFile(String? path) {
  return false; // Web không load file local
}

Widget buildFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit? fit,
  Widget Function()? onError,
}) {
  return onError != null ? onError() : const SizedBox();
}
