import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import './image_info_data.dart';

extension ImageSizeFunc on ImageInfoData {
  Future<ImageInfoData> resizeImage(
    final int? targetHeight,
    final int? targetWidth,
    final Uint8List bytes,
  ) async {
    final decodedImage = await decodeImageFromList(bytes);

    final height = _getTargetSize(decodedImage.height, targetHeight);

    final width = _getTargetSize(decodedImage.width, targetWidth);

    decodedImage.dispose();

    final codec = await instantiateImageCodec(
      bytes,
      targetHeight: height,
      targetWidth: width,
    );

    final frameInfo = await codec.getNextFrame();

    final targetUiImage = frameInfo.image;

    codec.dispose();

    final rezizedByteData = await targetUiImage.toByteData(
      format: ImageByteFormat.png,
    );

    final imageInfo = copyWith(
      memoryImage: MemoryImage(rezizedByteData!.buffer.asUint8List()),
      height: height?.toDouble() ?? targetUiImage.height.toDouble(),
      width: width?.toDouble() ?? targetUiImage.width.toDouble(),
    );

    targetUiImage.dispose();

    return imageInfo;
  }

  Future<ImageInfoData> setImageActualSize(final Uint8List bytes) async {
    final decodedImage = await decodeImageFromList(bytes);

    final imageInfo = copyWith(
      memoryImage: MemoryImage(bytes),
      height: decodedImage.height.toDouble(),
      width: decodedImage.width.toDouble(),
    );

    decodedImage.dispose();

    return imageInfo;
  }

  static int? _getTargetSize(final int imageSize, final int? targetSize) {
    if (targetSize == null || imageSize < targetSize) return null;

    return targetSize;
  }
}
