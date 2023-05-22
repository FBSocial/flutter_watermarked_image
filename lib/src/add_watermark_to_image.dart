import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_watermarked_image/src/watermark_config.dart';
import 'package:image/image.dart' as img;

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
          decoder is img.PngDecoder
              ? ImageByteFormat.png
              : ImageByteFormat.rawRgba,
          config,
        )),
  );

  final width = frames.first.image.width;
  final height = frames.first.image.height;

  if (decoder is img.GifDecoder) {
    final gifImage = img.Image.fromBytes(
        numChannels: 4,
        width: width,
        height: height,
        frameDuration: frames.first.duration.inMilliseconds,
        bytes: watermarkedFrames.first!.buffer);
    for (var i = 1; i < frames.length; i++) {
      gifImage.addFrame(img.Image.fromBytes(
          numChannels: 4,
          width: width,
          frameDuration: frames[i].duration.inMilliseconds,
          height: height,
          bytes: watermarkedFrames[i]!.buffer));
    }
    return img.encodeGif(gifImage, repeat: codec.repetitionCount);
  } else if (decoder is img.PngDecoder) {
    return watermarkedFrames.first!.buffer.asUint8List();
  } else {
    return img.encodeJpg(
        img.Image.fromBytes(
          width: width,
          height: height,
          numChannels: 4,
          bytes: watermarkedFrames.first!.buffer,
        ),
        quality: 80);
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

  for (final watermark in config) {
    watermark.draw(
      canvas,
      Size(width.toDouble(), height.toDouble()),
    );
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  return image.toByteData(format: outputImageByteFormat);
}
