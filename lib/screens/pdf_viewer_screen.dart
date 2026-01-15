import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PDFViewerScreen extends StatefulWidget {
  final String filePath; // Can be local path or URL
  final String title;

  const PDFViewerScreen({super.key, required this.filePath, required this.title});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.filePath.startsWith('http')) {
      _downloadFile(widget.filePath);
    } else {
      setState(() => isReady = true); // Local file (assuming valid)
    }
  }

  Future<void> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.title}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      setState(() {
        localPath = file.path;
        isReady = true;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Download error: $e';
      });
    }
  }

  String? localPath;

  @override
  Widget build(BuildContext context) {
    bool isUrl = widget.filePath.startsWith('http');
    String? path = isUrl ? localPath : widget.filePath;

    if (isUrl && localPath == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
           child: errorMessage.isNotEmpty 
             ? Text(errorMessage) 
             : const Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text('Downloading PDF...'),
                 ],
               )
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
            Center(child: Padding(
               padding: const EdgeInsets.only(right: 16.0),
               child: Text(pages != null ? '${currentPage! + 1} / $pages' : ''),
             )),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: path, // Use local path
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (_pages) {
              setState(() {
                pages = _pages;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              print(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              print('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // controller = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page;
              });
            },
          ),
          if(errorMessage.isNotEmpty)
            Center(child: Text('Error: $errorMessage')),
        ],
      ),
    );
  }
}
