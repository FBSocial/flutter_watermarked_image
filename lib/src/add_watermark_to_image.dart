import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_watermarked_image/src/watermark_config.dart';
import 'package:image/image.dart' as img;

class _DataPassToIsolate {
  final int width;
  final int height;
  final List<int> frameDuration;
  final int numFrames;
  final List<ByteBuffer> data;
  final int repetitionCount;

  _DataPassToIsolate(this.width, this.height, this.frameDuration,
      this.numFrames, this.data, this.repetitionCount);
}

Future<Uint8List> addWatermarkToImage(
  Uint8List srcData,
  List<WatermarkConfig> config,
) async {
  final data = await ImmutableBuffer.fromUint8List(srcData);
  final codec = await instantiateImageCodecFromBuffer(data);
  final frames = await Future.wait(
    List.generate(
      codec.frameCount,
      (i) => codec.getNextFrame(),
    ),
  );
  final decoder = img.findDecoderForData(srcData);
  final watermarkedFrames = await Future.wait(
    frames.map((e) => addWatermarkToFrame(
          e,
          isOutputFormatPng(decoder!)
              ? ImageByteFormat.png
              : ImageByteFormat.rawRgba,
          config,
        )),
  );
  final width = frames.first.image.width;
  final height = frames.first.image.height;

  if (decoder is img.GifDecoder) {
    return compute(
        _encodeGif,
        _DataPassToIsolate(
          width,
          height,
          frames.map((e) => e.duration.inMilliseconds).toList(),
          frames.length,
          watermarkedFrames.map((e) => e!.buffer).toList(),
          codec.repetitionCount,
        ));
  } else if (isOutputFormatPng(decoder!)) {
    return watermarkedFrames.first!.buffer.asUint8List();
  } else {
    return compute(
      _encodeJpeg,
      _DataPassToIsolate(
        width,
        height,
        [],
        1,
        [watermarkedFrames[0]!.buffer],
        0,
      ),
    );
  }
}

Future<ByteData?> addWatermarkToFrame(
  FrameInfo frame,
  ImageByteFormat outputImageByteFormat,
  List<WatermarkConfig> config,
) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();

  canvas.drawImage(frame.image, Offset.zero, paint);

  final width = frame.image.width;
  final height = frame.image.height;

  final size = Size(width.toDouble(), height.toDouble());
  for (final watermark in config) {
    final offset = watermark.getTranslation(size);
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(watermark.scale);
    watermark.draw(canvas, size);
    canvas.scale(1 / watermark.scale);
    canvas.translate(-offset.dx, -offset.dy);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  return image.toByteData(format: outputImageByteFormat);
}

bool isOutputFormatPng(img.Decoder decoder) =>
    decoder is img.PngDecoder ||
    decoder is img.TiffDecoder ||
    decoder is img.WebPDecoder;

FutureOr<Uint8List> _encodeGif(_DataPassToIsolate data) {
  final gifImage = img.Image.fromBytes(
      numChannels: 4,
      width: data.width,
      height: data.height,
      frameDuration: data.frameDuration.first,
      bytes: data.data.first);

  for (var i = 1; i < data.numFrames; i++) {
    gifImage.addFrame(
      img.Image.fromBytes(
        numChannels: 4,
        width: data.width,
        frameDuration: data.frameDuration[i],
        height: data.height,
        bytes: data.data[i],
      ),
    );
  }
  return img.encodeGif(gifImage, repeat: data.repetitionCount);
}

FutureOr<Uint8List> _encodeJpeg(_DataPassToIsolate data) {
  return img.encodeJpg(
      img.Image.fromBytes(
        width: data.width,
        height: data.height,
        numChannels: 4,
        bytes: data.data[0],
      ),
      quality: 80);
}
