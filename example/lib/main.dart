import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_watermarked_image/flutter_watermarked_image.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<WatermarkConfig> config;
  final ValueNotifier<Uint8List?> image = ValueNotifier(null);

  @override
  void initState() {
    ImageWatermarkConfig.fromAsset(
      assetName: "assets/flutter.png",
      position: const Offset(-96, -96),
    ).then((imageWatermarkConfig) {
      config = [
        TextWatermarkConfig(
          text: "Hello World",
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
          position: const Offset(20, 20),
        ),
        imageWatermarkConfig,
      ];
    });
    super.initState();
  }

  @override
  void dispose() {
    image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AspectRatio(
                aspectRatio: 1,
                child: ValueListenableBuilder<Uint8List?>(
                    valueListenable: image,
                    builder: (context, image, child) {
                      if (image == null) return const SizedBox();
                      return Image.memory(image);
                    })),
            ElevatedButton(
                onPressed: () async {
                  generateWatermarkedImage(
                      await WatermarkedImage.fromUrl(
                          Uri.parse(
                              "https://img2.baidu.com/it/u=417858554,4138815859&fm=253"),
                          config),
                      "watermarked_image_1.jpg");
                },
                child: const Text("add watermark to network image(jpg)")),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () async {
                  final srcFile = await generateLocalImage();
                  generateWatermarkedImage(
                      await WatermarkedImage.fromFile(srcFile, config),
                      "watermarked_image_2.gif");
                },
                child: const Text("add watermark to local image(gif)")),
          ],
        ),
      ),
    );
  }

  Future<File> generateLocalImage() async {
    final tmpPath = await getTemporaryDirectory();
    final srcImg = await rootBundle.load("assets/sample-animated-400x300.gif");
    File file = File("${tmpPath.path}/ori.gif");
    file.writeAsBytesSync(srcImg.buffer.asUint8List());
    return file;
  }

  generateWatermarkedImage(WatermarkedImage img, String outputName) async {
    image.value = await img.generateWatermarkedImage();

    if (context.mounted) {
      SnackBar snackBar = const SnackBar(
        content: Text("watermarked image generated"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
