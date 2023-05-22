This package is used to generate the data for a watermarked image, so that it can be saved to somewhere, rather than for displaying the watermarked

## Features

- Supports all image format supported by flutter, **including GIF**.
- Supports text watermarking, image watermarking, and customization by inheriting `WatermarkedImage`.
- Implemented via PictureRecorder, not pixel manipulation.

For PNG and GIF images, the original format will be maintained, while for other formats, the watermark generated will be in JPEG format.

## Getting started

Add `flutter_watermarked_image` as a dependency in your pubspec.yaml file.

```yaml
dependencies:
	...
  flutter_watermarked_image:
    git: https://github.com/FBSocial/flutter_watermarked_image.git
```

Import in your code:

```dart
import 'package:flutter_watermarked_image/flutter_watermarked_image.dart';
```

## Usage

Initialize watermark config:

```dart
final config = [
    TextWatermarkConfig(
      text: "Hello World",
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
      position: const Offset(20, 20),
    ),
    ImageWatermarkConfig.fromAsset(
      assetName: "assets/flutter.png",
      position: const Offset(-96, -96),
    ),
  ];
```

This code configures a text watermark in the top left corner and an image watermark in the bottom right corner.

Generate watermarked image:

```dart
final img = await WatermarkedImage.fromUrl(
  Uri.parse(
      "https://img2.baidu.com/it/u=417858554,4138815859&fm=253"),
  config);
final data = await img.generateWatermarkedImage();
```

You can write `data` to a file directly. The code above will generate the following image:

![watermarked_image_1](https://github.com/FBSocial/flutter_watermarked_image/assets/48704743/30dcb1f4-d142-458a-a2fa-d1974e4db093)

For a complete example, please refer to the example project.
