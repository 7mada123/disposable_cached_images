import 'dart:ui';

import 'package:flutter/material.dart';

import '../image_info_data.dart';

extension ImageSizeFunc on ImageInfoData {
  Future<ImageInfoData> resizeImage(final int targetWidth) async {
    final decodedImage = await decodeImageFromList(memoryImage!.bytes);

    if (decodedImage.width <= targetWidth) {
      final imageInfo = copyWith(
        width: decodedImage.width.toDouble(),
        height: decodedImage.height.toDouble(),
      );

      decodedImage.dispose();

      return imageInfo;
    }

    final codec = await instantiateImageCodec(
      memoryImage!.bytes,
      targetWidth: targetWidth,
    );

    final frameInfo = await codec.getNextFrame();

    final targetUiImage = frameInfo.image;

    if (targetUiImage.width == decodedImage.width) {
      final imageInfo = copyWith(
        width: decodedImage.width.toDouble(),
        height: decodedImage.height.toDouble(),
      );

      codec.dispose();
      targetUiImage.dispose();
      decodedImage.dispose();

      return imageInfo;
    }

    codec.dispose();

    decodedImage.dispose();

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
    final decodedImage = await decodeImageFromList(memoryImage!.bytes);

    final imageInfo = copyWith(
      height: decodedImage.height.toDouble(),
      width: decodedImage.width.toDouble(),
    );

    decodedImage.dispose();

    return imageInfo;
  }
}
