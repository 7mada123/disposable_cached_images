import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../image_info_data.dart';

extension ImageSizeFunc on ImageInfoData {
  Future<ImageInfoData> resizeImage(final int targetWidth) async {
    final imageDescriptor = await _getImageDescriptor(memoryImage!.bytes);

    if (imageDescriptor.width <= targetWidth) {
      final imageInfo = copyWith(
        width: imageDescriptor.width.toDouble(),
        height: imageDescriptor.height.toDouble(),
      );

      imageDescriptor.dispose();

      return imageInfo;
    }

    final codec = await imageDescriptor.instantiateCodec(
      targetWidth: targetWidth,
    );

    final frameInfo = await codec.getNextFrame();

    final targetUiImage = frameInfo.image;

    if (targetUiImage.width == imageDescriptor.width) {
      final imageInfo = copyWith(
        width: imageDescriptor.width.toDouble(),
        height: imageDescriptor.height.toDouble(),
      );

      imageDescriptor.dispose();
      codec.dispose();
      targetUiImage.dispose();

      return imageInfo;
    }

    imageDescriptor.dispose();
    codec.dispose();

    final rezizedByteData = await targetUiImage.toByteData(
      format: ImageByteFormat.png,
    );

    final imageInfo = copyWith(
      memoryImage: MemoryImage(rezizedByteData!.buffer.asUint8List()),
      height: targetUiImage.height.toDouble(),
      width: targetUiImage.width.toDouble(),
    );

    targetUiImage.dispose();

    return imageInfo;
  }

  Future<ImageInfoData> setImageSize() async {
    final imageDescriptor = await _getImageDescriptor(memoryImage!.bytes);

    final imageInfo = copyWith(
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
}
