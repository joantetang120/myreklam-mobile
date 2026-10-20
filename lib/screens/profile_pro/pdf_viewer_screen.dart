import 'package:myreklam/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String fileName;

  const PdfViewerScreen({super.key, required this.url, required this.fileName});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  final CancelToken _cancelToken = CancelToken();
  String? _ownedFilePath;

  @override
  void dispose() {
    _cancelToken.cancel();
    _removeOwnedFile();
    super.dispose();
  }

  Future<void> _removeOwnedFile() async {
    final path = _ownedFilePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      /* Only this viewer's temporary file; never user Downloads. */
    }
  }

  @override
  void initState() {
    super.initState();
    _downloadAndOpenPdf();
  }

  Future<void> _downloadAndOpenPdf() async {
    try {
      // Create a temporary file path
      final tempDir = await getTemporaryDirectory();
      final privateDir = Directory(
        '${tempDir.path}/myreklam_private_documents',
      );
      await privateDir.create(recursive: true);
      final safeName = widget.fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final fileName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
      final filePath = '${privateDir.path}/$fileName';
      _ownedFilePath = filePath;

      // Download the PDF
      final dio = Dio();
      await dio.download(widget.url, filePath, cancelToken: _cancelToken);

      if (!mounted) {
        await _removeOwnedFile();
        return;
      }

      setState(() {
        localPath = filePath;
        isLoading = false;
      });
    } catch (e) {
      await _removeOwnedFile();
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage =
            'Impossible de charger le document. Si le lien a expiré, fermez cet écran puis actualisez la liste des documents.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AdaptiveColors.surface(
          context,
          const Color(0xFFEF8A40),
        ),
        foregroundColor: AdaptiveColors.foreground(context, Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AdaptiveColors.foreground(
                      context,
                      Color(0xFFEF8A40),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Chargement du document...'),
                ],
              ),
            )
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AdaptiveColors.foreground(context, Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      _downloadAndOpenPdf();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdaptiveColors.surface(
                        context,
                        const Color(0xFFEF8A40),
                      ),
                      foregroundColor: AdaptiveColors.foreground(
                        context,
                        Colors.white,
                      ),
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : PDFView(
              filePath: localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              fitPolicy: FitPolicy.BOTH,
              onError: (error) {
                setState(() {
                  errorMessage = 'Erreur: $error';
                });
              },
            ),
    );
  }
}
