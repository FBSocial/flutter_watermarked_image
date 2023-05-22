import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_watermarked_image/flutter_watermarked_image.dart';
import 'package:http/http.dart' as http;

import 'add_watermark_to_image.dart';

/// `WatermarkedImage` is a class that represents an image with a watermark,
/// this class is used to generate the data for a watermarked image, so that
/// it can be saved to some place, rather than for displaying the watermarked
/// image
class WatermarkedImage {
  final List<WatermarkConfig> config;
  final Uint8List data;

  WatermarkedImage(this.data, this.config);

  static Future<WatermarkedImage> fromUrl(
      Uri url, List<WatermarkConfig> config) async {
    final data = await _imageDataFromNet(url);
    return WatermarkedImage(data, config);
  }

  static Future<WatermarkedImage> fromFile(
      File file, List<WatermarkConfig> config) async {
    final data = await file.readAsBytes();
    return WatermarkedImage(data, config);
  }

  static Future<Uint8List> _imageDataFromNet(Uri imageUrl) async {
    final response = await http.get(imageUrl);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw HttpException('Failed to load image from $imageUrl', uri: imageUrl);
    }
  }

  Future<Uint8List> generateWatermarkedImage() {
    return addWatermarkToImage(data, config);
  }
}
