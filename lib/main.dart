import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.setSize(const Size(450, 300));
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
  String? _encryption = "";
  double _dpi = 200;
  Future convert(String savePath) async {
    final pdf = pw.Document();
    final file = File(savePath);

    final openddPdf = await rootBundle.load(_openFilePath);
    var doc = openddPdf.buffer.asUint8List();

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
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: false, lockParentWindow: true);
    if (result != null) {
      setState(() {
        _openFilePath = result.files.first.path!;
      });
    } else {
      // User canceled the picker
    }
  }

  Future saveFile() async {
    var savePath = await FilePicker.platform
        .saveFile(allowedExtensions: ['pdf'], lockParentWindow: true);
    if (savePath != null) {
      return await convert(savePath);
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    // test();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("PDF Tools")),
        body: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(_openFilePath),
                Column(children: [
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
                          onChanged: (value) {
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
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: () => openFile(),
                          child: Flex(
                            direction: Axis.vertical,
                            children: const [
                              Icon(Icons.folder),
                              Text("Open pdf")
                            ],
                          )),
                      ElevatedButton(
                          onPressed: () async {
                            await saveFile();
                            showDialog(
                              context: context,
                              builder: (context) => Text("ok"),
                            );
                          },
                          child: Flex(
                            direction: Axis.vertical,
                            children: const [
                              Icon(Icons.save),
                              Text("save"),
                            ],
                          )),
                    ],
                  ),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}
