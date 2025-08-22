import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:hallomobil/constants/color/color_constants.dart';
import 'dart:io';

import 'package:hallomobil/data/models/pdf_model.dart';

class PdfDetailPage extends StatelessWidget {
  final Pdf pdf;
  final File pdfFile;

  const PdfDetailPage({super.key, required this.pdf, required this.pdfFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pdf.name),
        backgroundColor: ColorConstants.WHITE,
      ),
      body: PDFView(
        filePath: pdfFile.path,
        autoSpacing: true,
        enableSwipe: true,
        swipeHorizontal: true,
        pageFling: true,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF yüklenemedi: $error')),
          );
        },
      ),
    );
  }
}
