import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class LibraryPdfReaderScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final VoidCallback onBack;

  const LibraryPdfReaderScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.onBack,
  });

  @override
  State<LibraryPdfReaderScreen> createState() => _LibraryPdfReaderScreenState();
}

class _LibraryPdfReaderScreenState extends State<LibraryPdfReaderScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfViewerController? _pdfViewerController;
  Uint8List? _pdfBytes;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadPdfBytes();
  }

  Future<void> _loadPdfBytes() async {
    print(
      '[PDF Viewer] Starting download of PDF bytes from URL: ${widget.pdfUrl}',
    );
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        widget.pdfUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null) {
        setState(() {
          _pdfBytes = Uint8List.fromList(response.data!);
          _isLoading = false;
        });
        print(
          '[PDF Viewer] PDF bytes downloaded successfully. Size: ${_pdfBytes!.length} bytes',
        );
      } else {
        throw Exception("Response data is null");
      }
    } catch (e, stack) {
      print('[PDF Viewer ERROR] Failed to fetch PDF bytes: $e');
      print('[PDF Viewer ERROR] Stacktrace: $stack');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFC73024)),
                onPressed: widget.onBack,
                tooltip: "Back to Details",
              ),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFFC73024),
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, color: Color(0xFFC73024)),
                onPressed: () async {
                  final uri = Uri.parse(widget.pdfUrl);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open browser for ${widget.pdfUrl}')),
                      );
                    }
                  }
                },
                tooltip: "Open in Browser Reader",
              ),
              if (_pdfBytes != null) ...[
                IconButton(
                  icon: const Icon(Icons.zoom_in, color: Color(0xFFC73024)),
                  onPressed: () {
                    _pdfViewerController?.zoomLevel =
                        (_pdfViewerController?.zoomLevel ?? 1.0) + 0.25;
                  },
                  tooltip: "Zoom In",
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out, color: Color(0xFFC73024)),
                  onPressed: () {
                    _pdfViewerController?.zoomLevel =
                        (_pdfViewerController?.zoomLevel ?? 1.0) - 0.25;
                  },
                  tooltip: "Zoom Out",
                ),
              ],
            ],
          ),
        ),
        // PDF Viewer Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE29F5C), width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildViewerContent(),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildViewerContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFE29F5C)),
            SizedBox(height: 16),
            Text(
              "Loading document...",
              style: TextStyle(
                color: Color(0xFF8B5115),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Failed to load PDF",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadPdfBytes();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE29F5C),
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return SfPdfViewer.memory(
      _pdfBytes!,
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        print(
          '[PDF Viewer] Document loaded successfully! Total pages: ${details.document.pages.count}',
        );
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        print('================================================');
        print('[PDF Viewer ERROR] Memory load failed!');
        print('[PDF Viewer ERROR] Error Title: ${details.error}');
        print('[PDF Viewer ERROR] Description: ${details.description}');
        print('================================================');
      },
    );
  }
}
