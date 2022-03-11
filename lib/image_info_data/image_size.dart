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
    final imageDescriptor = await _getImageDescriptor(bytes);

    final height = _getTargetSize(imageDescriptor.height, targetHeight);

    final width = _getTargetSize(imageDescriptor.width, targetWidth);

    final codec = await imageDescriptor.instantiateCodec(
      targetHeight: height,
      targetWidth: width,
    );

    final frameInfo = await codec.getNextFrame();

    final targetUiImage = frameInfo.image;

    imageDescriptor.dispose();
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
    final imageDescriptor = await _getImageDescriptor(bytes);

    final imageInfo = copyWith(
      memoryImage: MemoryImage(bytes),
      height: imageDescriptor.height.toDouble(),
      width: imageDescriptor.width.toDouble(),
    );

    imageDescriptor.dispose();

    return imageInfo;
  }

  static Future<ImageDescriptor> _getImageDescriptor(
    final Uint8List bytes,
  ) async {
    final imageBuffer = await ImmutableBuffer.fromUint8List(bytes);

    final imageDescriptor = await ImageDescriptor.encoded(imageBuffer);

    imageBuffer.dispose();

    return imageDescriptor;
  }

  static int? _getTargetSize(final int imageSize, final int? targetSize) {
    if (targetSize == null || imageSize < targetSize) return null;

    return targetSize;
  }
}
