import 'dart:io';
import 'dart:ui' as ui;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    doWhenWindowReady(() {
      const initialSize = Size(600, 300);
      appWindow.minSize = initialSize;
      appWindow.maxSize = initialSize;
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.show();
    });
  }
  runApp(const MyApp());
}

// ignore: must_be_immutable
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _openFilePath = "";
  bool loading = false;
  String? _encryption = "";
  double _dpi = 200;
  @override
  Widget build(BuildContext context) {
    // test();
    return MaterialApp(
      home: Scaffold(
        //appBar: AppBar(title: const Text("PDF Tools")),
        body: Row(
          children: [
            RightSide(
                body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                          onPressed: (loading) ? null : () => openFile(),
                          child: Flex(
                            direction: Axis.vertical,
                            children: const [
                              Icon(Icons.folder),
                              Text("Open pdf")
                            ],
                          )),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: ElevatedButton(
                          onPressed: (_openFilePath.isEmpty || loading)
                              ? null
                              : () => saveFile(),
                          child: Flex(
                            direction: Axis.vertical,
                            children: const [
                              Icon(Icons.save),
                              Text("save"),
                            ],
                          )),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5)),
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              )),
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            child: Text(_openFilePath),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Text("Quality :"),
                    Expanded(
                      child: Slider(
                        min: 100,
                        max: 500,
                        divisions: 20,
                        label: _dpi.toString(),
                        value: _dpi,
                        onChanged: (_openFilePath.isEmpty || loading)
                            ? null
                            : (value) {
                                setState(() {
                                  _dpi = value;
                                });
                              },
                      ),
                    ),
                    Text(_dpi.toString()),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  enabled: (_openFilePath.isNotEmpty),
                  decoration: const InputDecoration(
                    labelText: 'Encrypt (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: _encryption),
                  onSubmitted: (value) {
                    setState(() {
                      _encryption = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
              ]),
            ))
          ],
        ),
      ),
    );
  }

  Future convert(String savePath) async {
    final pdf = pw.Document();
    final file = File(savePath);
    final doc = await File(_openFilePath).readAsBytes();
    // var tempDir = Directory.systemTemp.createTempSync();
    // int index = 1;

    await for (var page in Printing.raster(doc, dpi: _dpi)) {
      final image = await page.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);

      // await File("${tempDir.path}/tmp$index.png")
      //     .writeAsBytes(data!.buffer.asUint8List());
      pdf.addPage(pw.Page(
        pageFormat:
            PdfPageFormat(image.width.toDouble(), image.height.toDouble()),
        build: (pw.Context context) => pw.Center(
            child: pw.Image(pw.MemoryImage(data!.buffer.asUint8List()))),
      ));

      // index++;
    }

    return file.writeAsBytes(await pdf.save());
  }

  void openFile() async {
    setState(() {
      loading = true;
    });
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: false, lockParentWindow: true);
    if (result != null) {
      setState(() {
        _openFilePath = result.files.first.path!;
      });
    }
    setState(() {
      loading = false;
    });
  }

  Future saveFile() async {
    setState(() {
      loading = true;
    });
    var savePath = await FilePicker.platform
        .saveFile(allowedExtensions: ['pdf'], lockParentWindow: true);
    if (savePath != null) {
      await convert(savePath);
    }
    setState(() {
      loading = false;
    });
  }
}

final backgroundStartColor = Colors.grey.shade50;
final backgroundEndColor = Colors.grey.shade300;

// ignore: must_be_immutable
class RightSide extends StatelessWidget {
  RightSide({Key? key, required this.body}) : super(key: key);
  Widget body;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundStartColor, backgroundEndColor],
              stops: const [0.0, 1.0]),
        ),
        child: Column(children: [
          WindowTitleBarBox(
            child: Row(
              children: [
                Expanded(child: MoveWindow()),
                const WindowButtons(),
              ],
            ),
          ),
          body
        ]),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(),
        CloseWindowButton(),
      ],
    );
  }
}
