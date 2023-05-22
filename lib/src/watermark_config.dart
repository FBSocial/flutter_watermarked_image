import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Base class for watermark configuration, you can inherit this class to
/// implement watermark types in addition to the text and images provided by
/// default.
abstract class WatermarkConfig {
  /// The position of the watermark, it is calculated relative to the top left
  /// corner if it is positive, and relative to the bottom right corner if it is
  /// negative.
  final Offset position;

  WatermarkConfig(this.position);

  void draw(Canvas canvas, Size size);

  @protected
  Offset getOffset(Size size) {
    return Offset(
      position.dx > 0 ? position.dx : size.width + position.dx,
      position.dy > 0 ? position.dy : size.height + position.dy,
    );
  }
}

/// A watermark configuration that draws text onto the source image
class TextWatermarkConfig extends WatermarkConfig {
  final String text;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;

  TextWatermarkConfig({
    required this.text,
    required this.textStyle,
    this.textAlign = TextAlign.left,
    this.textDirection = TextDirection.ltr,
    required Offset position,
  }) : super(position);

  @override
  void draw(Canvas canvas, Size size) {
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: textDirection,
    );
    textPainter.layout();
    textPainter.paint(canvas, getOffset(size));
  }
}

/// A watermark configuration that draws an image onto the source image
class ImageWatermarkConfig extends WatermarkConfig {
  final ui.Image image;

  ImageWatermarkConfig({
    required this.image,
    required Offset position,
  }) : super(position);

  static Future<ImageWatermarkConfig> fromAsset({
    required String assetName,
    required Offset position,
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) {
    final imageAsset = AssetImage(assetName);
    final ImageStream stream = imageAsset.resolve(configuration);
    final Completer<ui.Image> completer = Completer();

    void listener(ImageInfo info, bool _) {
      completer.complete(info.image);
      stream.removeListener(ImageStreamListener(listener));
    }

    stream.addListener(ImageStreamListener(listener));

    return completer.future.then(
        (image) => ImageWatermarkConfig(image: image, position: position));
  }

  @override
  void draw(Canvas canvas, Size size) {
    canvas.drawImage(image, getOffset(size), Paint());
  }
}
