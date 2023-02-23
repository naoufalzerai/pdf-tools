import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  runApp(MyApp('PDF Tools'));
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  MyApp(this.title, {Key? key}) : super(key: key);
  final String title;
  String openFilePath = "";
  double dpi = 200;
  Future convert(String savePath) async {
    final pdf = pw.Document();
    final file = File(savePath);

    final openddPdf = await rootBundle.load(openFilePath);
    var doc = openddPdf.buffer.asUint8List();

    // var tempDir = Directory.systemTemp.createTempSync();
    // int index = 1;

    await for (var page in Printing.raster(doc, dpi: dpi)) {
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
      openFilePath = result.files.first.path!;
    } else {
      // User canceled the picker
    }
  }

  void saveFile() async {
    var savePath = await FilePicker.platform
        .saveFile(allowedExtensions: ['pdf'], lockParentWindow: true);
    if (savePath != null) {
      convert(savePath);
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    // test();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Column(
          children: [
            const Text("data"),
            ElevatedButton(
                onPressed: () => openFile(), child: const Text("open")),
            ElevatedButton(
                onPressed: () => saveFile(), child: const Text("save")),
          ],
        ),
      ),
    );
  }
}
