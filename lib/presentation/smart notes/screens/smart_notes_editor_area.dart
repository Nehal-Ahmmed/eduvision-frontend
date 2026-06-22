import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/note.dart';
import '../../theme/app_constants.dart';
import '../provider/notes_provider.dart';
import 'draw/smart_notes_custom_painter.dart';
import 'draw/smart_notes_drawing_board.dart';
import 'draw/smart_notes_whiteboard.dart';
import 'widgets/editable_table.dart';

class TextPageData {
  int pageNumber;
  final QuillController controller;
  final FocusNode focusNode;

  TextPageData({
    required this.pageNumber,
    required this.controller,
    required this.focusNode,
  });
}

class DrawPageData {
  int pageNumber;
  final DrawingController controller;

  DrawPageData({required this.pageNumber, required this.controller});
}

class WhiteboardPageData {
  int pageNumber;
  final List<WhiteboardItem> items;

  WhiteboardPageData({required this.pageNumber, required this.items});
}

class CombinedPage {
  int pageNumber;
  final String type; // 'text', 'draw', 'whiteboard'
  final dynamic data;

  CombinedPage({
    required this.pageNumber,
    required this.type,
    required this.data,
  });
}

class SmartNotesEditorArea extends ConsumerStatefulWidget {
  final int currentTab;
  final bool isEditMode;
  final bool isAiVisible;
  final Function(int) onTabChanged;
  final Function(bool) onEditModeChanged;
  final Function(bool) onAiVisibleChanged;
  final VoidCallback onToggleExplorer;

  const SmartNotesEditorArea({
    super.key,
    required this.currentTab,
    required this.isEditMode,
    required this.isAiVisible,
    required this.onTabChanged,
    required this.onEditModeChanged,
    required this.onAiVisibleChanged,
    required this.onToggleExplorer,
  });

  @override
  ConsumerState<SmartNotesEditorArea> createState() => _SmartNotesEditorAreaState();
}

class _SmartNotesEditorAreaState extends ConsumerState<SmartNotesEditorArea> {
  int? _loadedNoteId;
  bool _isMetadataVisible = true;

  // Local folder/tags state
  int? _currentParentId;
  String _currentSubject = 'Notes';
  final List<String> _currentTags = [];
  final TextEditingController _tagInputController = TextEditingController();

  // Multi-page state lists
  final List<TextPageData> _textPages = [];
  final List<DrawPageData> _drawPages = [];
  final List<WhiteboardPageData> _whiteboardPages = [];

  // Tracks which page currently has focus in Text tab to route toolbar actions
  int _focusedPageIndex = 0;
  bool _isLeftSidebarExpanded = true;
  bool _isRightSidebarExpanded = true;
  bool _initializedSidebars = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedSidebars) {
      final isNarrow = MediaQuery.of(context).size.width < 900;
      if (isNarrow) {
        _isLeftSidebarExpanded = false;
        _isRightSidebarExpanded = false;
      }
      _initializedSidebars = true;
    }
  }
  String? _textSidebarImage;
  String? _textRightSidebarImage;
  int _focusedDrawPageIndex = 0;
  int _focusedWhiteboardPageIndex = 0;

  // Pomodoro timer state for whiteboard
  Timer? _pomodoroTimer;
  int _pomodoroSeconds = 25 * 60;
  bool _isPomodoroRunning = false;
  bool _isBreakTime = false;

  @override
  void dispose() {
    _tagInputController.dispose();
    for (var p in _textPages) {
      p.controller.dispose();
      p.focusNode.dispose();
    }
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  void _loadNoteContent(String rawContent) {
    // Clear existing controllers and focus nodes to avoid leaks
    for (var p in _textPages) {
      p.controller.dispose();
      p.focusNode.dispose();
    }
    _textPages.clear();
    _drawPages.clear();
    _whiteboardPages.clear();
    _focusedPageIndex = 0;

    bool successfullyParsed = false;

    if (rawContent.startsWith('{') && rawContent.contains('"version":')) {
      try {
        final Map<String, dynamic> data = jsonDecode(rawContent);

        // 1. Load Text Pages
        if (data['textPages'] != null) {
          for (var p in data['textPages']) {
            final int pageNum = p['pageNumber'] ?? 1;
            final String deltaStr = p['delta'] ?? '';
            Document doc;
            if (deltaStr.startsWith('[') || deltaStr.startsWith('{')) {
              doc = Document.fromJson(jsonDecode(deltaStr));
            } else {
              doc = Document()..insert(0, deltaStr);
            }
            final controller = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
            final focusNode = FocusNode();
            final pageData = TextPageData(
              pageNumber: pageNum,
              controller: controller,
              focusNode: focusNode,
            );
            focusNode.addListener(() {
              if (focusNode.hasFocus) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final idx = _textPages.indexOf(pageData);
                    if (idx != -1 && _focusedPageIndex != idx) {
                      setState(() {
                        _focusedPageIndex = idx;
                      });
                    }
                  }
                });
              }
            });
            _textPages.add(pageData);
          }
        }

        // 2. Load Draw Pages
        if (data['drawStrokes'] != null) {
          for (var p in data['drawStrokes']) {
            final int pageNum = p['pageNumber'] ?? 1;
            final String strokesJson = p['strokes'] ?? '';
            final controller = DrawingController();
            controller.loadStrokesFromJson(strokesJson);
            _drawPages.add(DrawPageData(pageNumber: pageNum, controller: controller));
          }
        }

        // 3. Load Whiteboard Pages
        if (data['whiteboardItems'] != null) {
          for (var p in data['whiteboardItems']) {
            final int pageNum = p['pageNumber'] ?? 1;
            final List itemsList = p['items'] ?? [];
            final List<WhiteboardItem> items =
                itemsList.map((i) => WhiteboardItem.fromJson(i)).toList();
            _whiteboardPages.add(WhiteboardPageData(pageNumber: pageNum, items: items));
          }
        }

        successfullyParsed = true;
      } catch (_) {
        successfullyParsed = false;
      }
    }

    // Fallback/Legacy Note: Parse rawContent into Page 1
    if (!successfullyParsed) {
      final doc = Document()..insert(0, rawContent);
      final focusNode = FocusNode();
      final pageData = TextPageData(
        pageNumber: 1,
        controller: QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        ),
        focusNode: focusNode,
      );
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final idx = _textPages.indexOf(pageData);
              if (idx != -1 && _focusedPageIndex != idx) {
                setState(() {
                  _focusedPageIndex = idx;
                });
              }
            }
          });
        }
      });
      _textPages.add(pageData);

      _drawPages.add(DrawPageData(
        pageNumber: 1,
        controller: DrawingController(),
      ));

      _whiteboardPages.add(WhiteboardPageData(
        pageNumber: 1,
        items: [],
      ));
    }

    _sortPages();
  }

  void _sortPages() {
    _textPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    _drawPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    _whiteboardPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }

  void _resolveDuplicatePageNumbers() {
    final List<CombinedPage> all = [];
    for (var p in _textPages) {
      all.add(CombinedPage(pageNumber: p.pageNumber, type: 'text', data: p));
    }
    for (var p in _drawPages) {
      all.add(CombinedPage(pageNumber: p.pageNumber, type: 'draw', data: p));
    }
    for (var p in _whiteboardPages) {
      all.add(CombinedPage(pageNumber: p.pageNumber, type: 'whiteboard', data: p));
    }

    // Sort by current numbers
    all.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    // Resolve duplicates (shifting forward)
    for (int i = 0; i < all.length; i++) {
      if (i > 0 && all[i].pageNumber <= all[i - 1].pageNumber) {
        all[i].pageNumber = all[i - 1].pageNumber + 1;
      }
    }

    // Write resolved values back to pages
    for (var cp in all) {
      if (cp.type == 'text') {
        (cp.data as TextPageData).pageNumber = cp.pageNumber;
      } else if (cp.type == 'draw') {
        (cp.data as DrawPageData).pageNumber = cp.pageNumber;
      } else if (cp.type == 'whiteboard') {
        (cp.data as WhiteboardPageData).pageNumber = cp.pageNumber;
      }
    }

    _sortPages();
  }

  String _serializeContent() {
    // Resolve any page number conflicts before serialization
    _resolveDuplicatePageNumbers();

    final Map<String, dynamic> data = {
      'version': 2,
      'textPages': _textPages
          .map((p) => {
                'pageNumber': p.pageNumber,
                'delta': jsonEncode(p.controller.document.toDelta().toJson()),
              })
          .toList(),
      'drawStrokes': _drawPages
          .map((p) => {
                'pageNumber': p.pageNumber,
                'strokes': p.controller.getStrokesJson(),
              })
          .toList(),
      'whiteboardItems': _whiteboardPages
          .map((p) => {
                'pageNumber': p.pageNumber,
                'items': p.items.map((i) => i.toJson()).toList(),
              })
          .toList(),
    };
    return jsonEncode(data);
  }

  Map<String, dynamic>? _parseMarkdownTable(String text) {
    return parseMarkdownTable(text);
  }

  Future<String?> _convertTableMarkdownToPngDataUrl(Map<String, dynamic> parsedTable) async {
    try {
      final headers = parsedTable['headers'] as List<String>;
      final rows = parsedTable['rows'] as List<List<String>>;

      const double cellPaddingX = 8.0;
      const double cellPaddingY = 5.0;
      const double maxColWidth = 140.0;
      const double minColWidth = 60.0;

      final int numCols = headers.length;
      final int numRows = rows.length + 1;

      final List<double> colWidths = List<double>.filled(numCols, minColWidth);
      final List<double> rowHeights = List<double>.filled(numRows, 0.0);

      // Create TextPainters for headers
      final headerPainters = <TextPainter>[];
      for (int col = 0; col < numCols; col++) {
        final tp = TextPainter(
          text: TextSpan(
            text: headers[col],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 9.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: maxColWidth);
        headerPainters.add(tp);
        if (tp.width + cellPaddingX * 2 > colWidths[col]) {
          colWidths[col] = (tp.width + cellPaddingX * 2).clamp(minColWidth, maxColWidth);
        }
        if (tp.height + cellPaddingY * 2 > rowHeights[0]) {
          rowHeights[0] = tp.height + cellPaddingY * 2;
        }
      }

      // Create TextPainters for rows
      final cellPainters = <List<TextPainter>>[];
      for (int r = 0; r < rows.length; r++) {
        final rowData = rows[r];
        final rowTextPainters = <TextPainter>[];
        for (int col = 0; col < numCols; col++) {
          final text = col < rowData.length ? rowData[col] : '';
          final tp = TextPainter(
            text: TextSpan(
              text: text,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 8.5,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: maxColWidth);
          rowTextPainters.add(tp);
          if (tp.width + cellPaddingX * 2 > colWidths[col]) {
            colWidths[col] = (tp.width + cellPaddingX * 2).clamp(minColWidth, maxColWidth);
          }
          if (tp.height + cellPaddingY * 2 > rowHeights[r + 1]) {
            rowHeights[r + 1] = tp.height + cellPaddingY * 2;
          }
        }
        cellPainters.add(rowTextPainters);
      }

      final double totalWidth = colWidths.reduce((a, b) => a + b);
      final double totalHeight = rowHeights.reduce((a, b) => a + b);

      // Render at 3x scale for crystal-clear quality
      const double scale = 3.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, totalWidth * scale, totalHeight * scale));
      
      canvas.scale(scale);

      double currentY = 0.0;
      for (int r = 0; r < numRows; r++) {
        final double rowHeight = rowHeights[r];
        final Rect rowRect = Rect.fromLTWH(0, currentY, totalWidth, rowHeight);

        final Paint bgPaint = Paint();
        if (r == 0) {
          bgPaint.color = const Color(0xFF3B82F6);
        } else {
          bgPaint.color = (r % 2 == 1) ? Colors.white : const Color(0xFFF3F4F6);
        }
        canvas.drawRect(rowRect, bgPaint);

        double currentX = 0.0;
        for (int col = 0; col < numCols; col++) {
          final double colWidth = colWidths[col];
          final TextPainter tp = (r == 0) ? headerPainters[col] : cellPainters[r - 1][col];

          final double py = currentY + (rowHeight - tp.height) / 2;
          final double px = currentX + cellPaddingX;
          tp.paint(canvas, Offset(px, py));

          currentX += colWidth;
        }

        currentY += rowHeight;
      }

      final Paint borderPaint = Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      double currentX = 0.0;
      for (int col = 0; col <= numCols; col++) {
        canvas.drawLine(Offset(currentX, 0), Offset(currentX, totalHeight), borderPaint);
        if (col < numCols) currentX += colWidths[col];
      }

      currentY = 0.0;
      for (int r = 0; r <= numRows; r++) {
        canvas.drawLine(Offset(0, currentY), Offset(totalWidth, currentY), borderPaint);
        if (r < numRows) currentY += rowHeights[r];
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage((totalWidth * scale).toInt(), (totalHeight * scale).toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final base64Str = base64Encode(bytes);
      return 'data:image/png;base64,$base64Str';
    } catch (e) {
      debugPrint('Error converting table: $e');
      return null;
    }
  }

  Future<void> _handleClipboardPaste() async {
    try {
      final bytes = await Pasteboard.image;
      if (!mounted) return;
      if (bytes != null) {
        final base64Str = base64Encode(bytes);
        final dataUrl = 'data:image/png;base64,$base64Str';
        _pasteImageToActivePage(dataUrl);
      } else {
        final ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        if (!mounted) return;
        if (clipboardData != null && clipboardData.text != null) {
          final text = clipboardData.text!.trim();
          if (text.startsWith('data:image/') || text.startsWith('http://') || text.startsWith('https://')) {
            _pasteImageToActivePage(text);
          } else {
            // Check if clipboard contains a table
            final parsedTable = _parseMarkdownTable(text);
            if (parsedTable != null) {
              final int activeTab = widget.currentTab.clamp(0, 2);
              if (activeTab == 0) {
                // Text tab: Insert as custom 'table' block embed!
                if (_textPages.isNotEmpty) {
                  final page = _textPages[_focusedPageIndex];
                  final controller = page.controller;
                  final index = controller.selection.baseOffset;
                  final insertIndex = (index >= 0 && index < controller.document.length)
                      ? index
                      : controller.document.length - 1;
                  controller.document.insert(insertIndex, BlockEmbed('table', text));
                  return;
                }
              } else if (activeTab == 2) {
                // Whiteboard tab: Insert as custom 'table' whiteboard item!
                if (_whiteboardPages.isNotEmpty) {
                  final page = _whiteboardPages[_focusedWhiteboardPageIndex];
                  setState(() {
                    page.items.add(WhiteboardItem(
                      id: const Uuid().v4(),
                      position: const Offset(150, 150),
                      type: 'table',
                      content: text,
                      colorValue: Colors.white.value,
                      width: 380.0,
                      height: 220.0,
                    ));
                  });
                  return;
                }
              } else {
                // Draw tab: Convert to 3x scaled PNG and paste it!
                final tableDataUrl = await _convertTableMarkdownToPngDataUrl(parsedTable);
                if (!mounted) return;
                if (tableDataUrl != null) {
                  _pasteImageToActivePage(tableDataUrl);
                  return;
                }
              }
            }

            // Otherwise, if in Text tab, paste text normally
            final int activeTab = widget.currentTab.clamp(0, 2);
            if (activeTab == 0 && _textPages.isNotEmpty) {
              final page = _textPages[_focusedPageIndex];
              final controller = page.controller;
              final index = controller.selection.baseOffset;
              final insertIndex = (index >= 0 && index < controller.document.length)
                  ? index
                  : controller.document.length - 1;
              controller.document.insert(insertIndex, clipboardData.text!);
              controller.updateSelection(
                TextSelection.collapsed(offset: insertIndex + clipboardData.text!.length),
                ChangeSource.local,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clipboard does not contain a valid image, table or image link.')),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clipboard is empty or contains no image.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to paste from clipboard: $e')),
      );
    }
  }

  void _pasteImageToActivePage(String imageUrl) {
    final int tab = widget.currentTab.clamp(0, 2);
    if (tab == 0) {
      if (_textPages.isNotEmpty) {
        final page = _textPages[_focusedPageIndex];
        final controller = page.controller;
        final index = controller.selection.baseOffset;
        controller.document.insert(index, BlockEmbed.image(imageUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image pasted to Text page!')),
        );
      }
    } else if (tab == 1) {
      if (_drawPages.isNotEmpty) {
        final page = _drawPages[_focusedDrawPageIndex];
        page.controller.addImageStroke(imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image pasted to Drawing board!')),
        );
      }
    } else if (tab == 2) {
      if (_whiteboardPages.isNotEmpty) {
        final page = _whiteboardPages[_focusedWhiteboardPageIndex];
        setState(() {
          page.items.add(WhiteboardItem(
            id: const Uuid().v4(),
            position: const Offset(100, 100),
            type: 'image',
            content: imageUrl,
            colorValue: Colors.transparent.value,
            width: 250.0,
            height: 180.0,
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image pasted to Whiteboard!')),
        );
      }
    }
  }

  void _addTag() {
    final tagText = _tagInputController.text.trim();
    if (tagText.isNotEmpty && !_currentTags.contains(tagText)) {
      setState(() {
        _currentTags.add(tagText);
        _tagInputController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _currentTags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeNoteId = ref.watch(activeNoteIdProvider);
    final notesState = ref.watch(notesProvider);

    final Note? activeNote = activeNoteId != null
        ? notesState.maybeWhen(
            data: (notes) {
              try {
                return notes.firstWhere((n) => n.id == activeNoteId);
              } catch (_) {}
              return null;
            },
            orElse: () => null,
          )
        : null;

    final folders = notesState.maybeWhen(
      data: (notes) => notes.where((n) => n.isFolder).toList(),
      orElse: () => <Note>[],
    );

    if (activeNote != null && _loadedNoteId != activeNote.id) {
      _loadedNoteId = activeNote.id;
      _currentParentId = activeNote.parentId;
      _currentSubject = activeNote.subject.isEmpty ? 'Notes' : activeNote.subject;
      _currentTags.clear();
      if (activeNote.tags.isNotEmpty) {
        _currentTags.addAll(activeNote.tags.split(',').map((t) => t.trim()));
      }
      _loadNoteContent(activeNote.content);
    } else if (activeNote == null && _loadedNoteId != null) {
      _loadedNoteId = null;
      _currentParentId = null;
      _currentSubject = 'Notes';
      _currentTags.clear();
      _loadNoteContent('');
    }

    final isNarrow = MediaQuery.of(context).size.width < 900;
    final int tab = widget.currentTab.clamp(0, 2);

    return Container(
      color: SmartNotesTheme.bgMain,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 12 : 24,
              vertical: isNarrow ? 8 : 16,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: SmartNotesTheme.border)),
            ),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.view_sidebar_outlined, color: SmartNotesTheme.iconColor),
                            onPressed: widget.onToggleExplorer,
                            tooltip: 'Toggle Explorer Sidebar',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(_isMetadataVisible ? Icons.expand_less : Icons.expand_more,
                                color: SmartNotesTheme.iconColor),
                            onPressed: () => setState(() => _isMetadataVisible = !_isMetadataVisible),
                            tooltip: 'Toggle Metadata',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              activeNote != null
                                  ? (widget.isEditMode
                                      ? activeNote.topic
                                      : '${activeNote.topic} (View Mode)')
                                  : 'Select or Create a Note',
                              style: const TextStyle(
                                color: SmartNotesTheme.textMain,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (activeNote != null && !widget.isEditMode)
                            _buildActionBtn(
                                'Edit', Icons.edit_outlined, () => widget.onEditModeChanged(true)),
                        ],
                      ),
                      if (activeNote != null && widget.isEditMode) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTabBtn('Text', Icons.text_fields, 0),
                              const SizedBox(width: 6),
                              _buildTabBtn('Draw', Icons.draw_outlined, 1),
                              const SizedBox(width: 6),
                              _buildTabBtn('Whiteboard', Icons.dashboard_outlined, 2),
                              const SizedBox(width: 6),
                              _buildAiTabBtn('AI Assistant', Icons.smart_toy_outlined),
                              const SizedBox(width: 12),
                              _buildActionBtn('Paste Image', Icons.paste_outlined, _handleClipboardPaste),
                              const SizedBox(width: 6),
                              _buildActionBtn('Save', Icons.save_outlined, () async {
                                // Apply sorting and serialization
                                final serialized = _serializeContent();
                                await ref.read(notesProvider.notifier).updateNote(
                                      activeNote.id,
                                      serialized,
                                      _currentSubject,
                                      activeNote.topic,
                                      parentId: _currentParentId,
                                      tags: _currentTags.join(','),
                                    );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Note merged and saved successfully!'),
                                    backgroundColor: SmartNotesTheme.accentBlue,
                                  ),
                                );
                                widget.onEditModeChanged(false);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.view_sidebar_outlined, color: SmartNotesTheme.iconColor),
                        onPressed: widget.onToggleExplorer,
                        tooltip: 'Toggle Explorer Sidebar',
                      ),
                      IconButton(
                        icon: Icon(_isMetadataVisible ? Icons.expand_less : Icons.expand_more,
                            color: SmartNotesTheme.iconColor),
                        onPressed: () => setState(() => _isMetadataVisible = !_isMetadataVisible),
                        tooltip: 'Toggle Metadata',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activeNote != null
                              ? (widget.isEditMode
                                  ? activeNote.topic
                                  : '${activeNote.topic} (View Mode)')
                              : 'Select or Create a Note',
                          style: const TextStyle(
                            color: SmartNotesTheme.textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activeNote != null) ...[
                        if (widget.isEditMode)
                          Flexible(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTabBtn('Text', Icons.text_fields, 0),
                                  const SizedBox(width: 8),
                                  _buildTabBtn('Draw', Icons.draw_outlined, 1),
                                  const SizedBox(width: 8),
                                  _buildTabBtn('Whiteboard', Icons.dashboard_outlined, 2),
                                  const SizedBox(width: 8),
                                  _buildAiTabBtn('AI Assistant', Icons.smart_toy_outlined),
                                  const SizedBox(width: 16),
                                  _buildActionBtn('Paste Image', Icons.paste_outlined, _handleClipboardPaste),
                                  const SizedBox(width: 8),
                                  _buildActionBtn('Save', Icons.save_outlined, () async {
                                    // Apply sorting and serialization
                                    final serialized = _serializeContent();
                                    await ref.read(notesProvider.notifier).updateNote(
                                          activeNote.id,
                                          serialized,
                                          _currentSubject,
                                          activeNote.topic,
                                          parentId: _currentParentId,
                                          tags: _currentTags.join(','),
                                        );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Note merged and saved successfully!'),
                                        backgroundColor: SmartNotesTheme.accentBlue,
                                      ),
                                    );
                                    widget.onEditModeChanged(false);
                                  }),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          _buildActionBtn(
                              'Edit', Icons.edit_outlined, () => widget.onEditModeChanged(true)),
                        ]
                      ]
                    ],
                  ),
          ),

          // Metadata Panel (Folder & Tags)
          if (_isMetadataVisible)
            Padding(
              padding: EdgeInsets.all(isNarrow ? 12.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Folder: ',
                          style: TextStyle(color: SmartNotesTheme.textMuted, fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: SmartNotesTheme.bgSecondary,
                          borderRadius: BorderRadius.circular(SmartNotesTheme.radiusSmall),
                          border: Border.all(color: SmartNotesTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _currentParentId,
                            dropdownColor: SmartNotesTheme.bgSecondary,
                            style: SmartNotesTheme.bodySmall,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: SmartNotesTheme.iconColor, size: 16),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Notes (Root)',
                                    style: TextStyle(color: SmartNotesTheme.textMain)),
                              ),
                              ...folders.map((folder) => DropdownMenuItem<int?>(
                                    value: folder.id,
                                    child: Text(folder.topic,
                                        style: const TextStyle(color: SmartNotesTheme.textMain)),
                                  )),
                            ],
                            onChanged: widget.isEditMode
                                ? (newParentId) {
                                    setState(() {
                                      _currentParentId = newParentId;
                                      if (newParentId == null) {
                                        _currentSubject = 'Notes';
                                      } else {
                                        final folder =
                                            folders.firstWhere((f) => f.id == newParentId);
                                        _currentSubject = folder.topic;
                                      }
                                    });
                                  }
                                : null,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Icon(Icons.local_offer_outlined,
                            color: SmartNotesTheme.iconColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ..._currentTags
                                .map((tag) => _buildRemovableTag(tag, widget.isEditMode)),
                            if (widget.isEditMode) ...[
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 100,
                                height: 24,
                                child: TextField(
                                  controller: _tagInputController,
                                  style: const TextStyle(fontSize: 12, color: SmartNotesTheme.textMain),
                                  decoration: const InputDecoration(
                                    hintText: 'Add tag...',
                                    hintStyle:
                                        TextStyle(color: SmartNotesTheme.textMuted, fontSize: 12),
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    border: UnderlineInputBorder(),
                                    enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: SmartNotesTheme.border)),
                                    focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: SmartNotesTheme.accentBlue)),
                                  ),
                                  onSubmitted: (_) => _addTag(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _addTag,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: SmartNotesTheme.accent,
                                    borderRadius: BorderRadius.circular(SmartNotesTheme.radiusSmall),
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                      color: SmartNotesTheme.iconDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, color: SmartNotesTheme.iconColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Created: ${activeNote != null ? activeNote.createdAt.toLocal().toString().split(' ')[0].replaceAll('-', '/') : 'N/A'}',
                            style: SmartNotesTheme.caption,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.update, color: SmartNotesTheme.iconColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Updated: ${activeNote != null ? activeNote.updatedAt.toLocal().toString().split(' ')[0].replaceAll('-', '/') : 'N/A'}',
                            style: SmartNotesTheme.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const Divider(color: SmartNotesTheme.border, height: 1),

          // Editor Page Stack Area
          Expanded(
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.keyV, control: true): _handleClipboardPaste,
              },
              child: Focus(
                autofocus: true,
                child: Container(
                  margin: isNarrow ? const EdgeInsets.all(8) : const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SmartNotesTheme.bgSecondary,
                borderRadius: BorderRadius.circular(SmartNotesTheme.radiusMedium),
                border: Border.all(color: SmartNotesTheme.border),
              ),
              clipBehavior: Clip.hardEdge,
              child: activeNote == null
                  ? const Center(
                      child: Text(
                        'Select a note from the left explorer sidebar or create a new one to begin editing.',
                        style: TextStyle(
                          color: SmartNotesTheme.textMuted,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Sidebar Panel
                        if (widget.isEditMode && tab < 3 && _isLeftSidebarExpanded)
                          Container(
                            width: isNarrow ? 180 : 220,
                            decoration: const BoxDecoration(
                              color: SmartNotesTheme.bgSecondary,
                              border: Border(right: BorderSide(color: SmartNotesTheme.border)),
                            ),
                            child: _buildLeftSidebarContent(),
                          ),

                        // Left Toggle Button
                        if (widget.isEditMode && tab < 3)
                          _buildSidebarToggle(
                            isLeft: true,
                            isExpanded: _isLeftSidebarExpanded,
                            onTap: () => setState(() => _isLeftSidebarExpanded = !_isLeftSidebarExpanded),
                          ),

                        // Main Scrollable Editor Area
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.isEditMode && tab == 0) _buildRichToolbar(),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Center(
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 900),
                                      padding: EdgeInsets.all(isNarrow ? 12.0 : 24.0),
                                      child: Column(
                                        children: [
                                          if (widget.isEditMode)
                                            _buildTabPagesList()
                                          else
                                            _buildMergedViewList(),
                                          if (widget.isEditMode) _buildAddPageButton(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right Toggle Button
                        if (widget.isEditMode && tab < 3 && tab != 1)
                          _buildSidebarToggle(
                            isLeft: false,
                            isExpanded: _isRightSidebarExpanded,
                            onTap: () => setState(() => _isRightSidebarExpanded = !_isRightSidebarExpanded),
                          ),

                        // Right Sidebar Panel
                        if (widget.isEditMode && tab < 3 && tab != 1 && _isRightSidebarExpanded)
                          Container(
                            width: isNarrow ? 180 : 220,
                            decoration: const BoxDecoration(
                              color: SmartNotesTheme.bgSecondary,
                              border: Border(left: BorderSide(color: SmartNotesTheme.border)),
                            ),
                            child: _buildRightSidebarContent(),
                          ),
                      ],
                    ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Edit Mode view lists by Tab
  Widget _buildTabPagesList() {
    final int tab = widget.currentTab.clamp(0, 2);
    if (tab == 0) {
      // Text Tab (Editable Rich Text list)
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _textPages.length,
        itemBuilder: (context, index) {
          final page = _textPages[index];
          return _buildPageCard(
            pageNumber: page.pageNumber,
            onPageNumberChanged: (newNum) {
              setState(() {
                page.pageNumber = newNum;
                _sortPages();
              });
            },
            onDelete: _textPages.length > 1
                ? () {
                    setState(() {
                      page.controller.dispose();
                      page.focusNode.dispose();
                      _textPages.removeAt(index);
                      if (_focusedPageIndex >= _textPages.length) {
                        _focusedPageIndex = _textPages.length - 1;
                      }
                    });
                  }
                : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 700),
              padding: const EdgeInsets.all(32),
              child: QuillEditor.basic(
                controller: page.controller,
                focusNode: page.focusNode,
                config: QuillEditorConfig(
                  placeholder: 'Start writing on page ${page.pageNumber}...',
                  autoFocus: false,
                  scrollable: false,
                  expands: false,
                  embedBuilders: [
                    Base64ImageEmbedBuilder(),
                    TableEmbedBuilder(),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else if (tab == 1) {
      // Draw Tab
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _drawPages.length,
        itemBuilder: (context, index) {
          final page = _drawPages[index];
          final isFocused = _focusedDrawPageIndex == index;
          return _buildPageCard(
            pageNumber: page.pageNumber,
            onPageNumberChanged: (newNum) {
              setState(() {
                page.pageNumber = newNum;
                _sortPages();
              });
            },
            onDelete: _drawPages.length > 1
                ? () {
                    setState(() {
                      _drawPages.removeAt(index);
                      if (_focusedDrawPageIndex >= _drawPages.length) {
                        _focusedDrawPageIndex = _drawPages.length - 1;
                      }
                    });
                  }
                : null,
            child: GestureDetector(
              onTapDown: (_) {
                if (_focusedDrawPageIndex != index) {
                  setState(() {
                    _focusedDrawPageIndex = index;
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isFocused ? SmartNotesTheme.accentBlue : Colors.transparent,
                    width: 2.0,
                  ),
                ),
                height: 600,
                child: SmartNotesDrawingBoard(
                  controller: page.controller,
                  isEditMode: true,
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Whiteboard Tab
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _whiteboardPages.length,
        itemBuilder: (context, index) {
          final page = _whiteboardPages[index];
          final isFocused = _focusedWhiteboardPageIndex == index;
          return _buildPageCard(
            pageNumber: page.pageNumber,
            onPageNumberChanged: (newNum) {
              setState(() {
                page.pageNumber = newNum;
                _sortPages();
              });
            },
            onDelete: _whiteboardPages.length > 1
                ? () {
                    setState(() {
                      _whiteboardPages.removeAt(index);
                      if (_focusedWhiteboardPageIndex >= _whiteboardPages.length) {
                        _focusedWhiteboardPageIndex = _whiteboardPages.length - 1;
                      }
                    });
                  }
                : null,
            child: GestureDetector(
              onTapDown: (_) {
                if (_focusedWhiteboardPageIndex != index) {
                  setState(() {
                    _focusedWhiteboardPageIndex = index;
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isFocused ? SmartNotesTheme.accentBlue : Colors.transparent,
                    width: 2.0,
                  ),
                ),
                height: 600,
                child: SmartNotesWhiteboard(
                  items: page.items,
                  isEditMode: true,
                  onChanged: () {
                    setState(() {});
                  },
                ),
              ),
            ),
          );
        },
      );
    }
  }

  // Unified Merged view in Read-Only Mode sorted by page number
  Widget _buildMergedViewList() {
    final List<CombinedPage> viewPages = [];
    for (var p in _textPages) {
      viewPages.add(CombinedPage(pageNumber: p.pageNumber, type: 'text', data: p));
    }
    for (var p in _drawPages) {
      viewPages.add(CombinedPage(pageNumber: p.pageNumber, type: 'draw', data: p));
    }
    for (var p in _whiteboardPages) {
      viewPages.add(CombinedPage(pageNumber: p.pageNumber, type: 'whiteboard', data: p));
    }

    // Sort all pages combined
    viewPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    if (viewPages.isEmpty) {
      return const Center(
        child: Text('This note is empty.', style: TextStyle(color: SmartNotesTheme.textMuted)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewPages.length,
      itemBuilder: (context, index) {
        final cp = viewPages[index];
        Widget pageWidget;

        if (cp.type == 'text') {
          final tPage = cp.data as TextPageData;
          pageWidget = Container(
            constraints: const BoxConstraints(minHeight: 700),
            padding: const EdgeInsets.all(32),
            child: QuillEditor.basic(
              controller: tPage.controller,
              focusNode: FocusNode(),
              config: QuillEditorConfig(
                autoFocus: false,
                scrollable: false,
                expands: false,
                embedBuilders: [
                  Base64ImageEmbedBuilder(),
                  TableEmbedBuilder(),
                ],
              ),
            ),
          );
        } else if (cp.type == 'draw') {
          final dPage = cp.data as DrawPageData;
          pageWidget = SizedBox(
            height: 600,
            child: SmartNotesDrawingBoard(
              controller: dPage.controller,
              isEditMode: false,
            ),
          );
        } else {
          final wPage = cp.data as WhiteboardPageData;
          pageWidget = Container(
            height: 600,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SmartNotesWhiteboard(
              items: wPage.items,
              isEditMode: false,
              onChanged: () {},
            ),
          );
        }

        return _buildPageCard(
          pageNumber: cp.pageNumber,
          onPageNumberChanged: (_) {},
          onDelete: null,
          child: pageWidget,
        );
      },
    );
  }

  Widget _buildAddPageButton() {
    final int tab = widget.currentTab.clamp(0, 2);
    if (!widget.isEditMode) return const SizedBox.shrink();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              if (tab == 0) {
                final maxNum = _textPages
                    .map((p) => p.pageNumber)
                    .fold(0, (max, e) => e > max ? e : max);
                final focusNode = FocusNode();
                final pageData = TextPageData(
                  pageNumber: maxNum + 1,
                  controller: QuillController.basic(),
                  focusNode: focusNode,
                );
                focusNode.addListener(() {
                  if (focusNode.hasFocus) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        final idx = _textPages.indexOf(pageData);
                        if (idx != -1 && _focusedPageIndex != idx) {
                          setState(() {
                            _focusedPageIndex = idx;
                          });
                        }
                      }
                    });
                  }
                });
                _textPages.add(pageData);
                _focusedPageIndex = _textPages.length - 1;
              } else if (widget.currentTab == 1) {
                final maxNum = _drawPages
                    .map((p) => p.pageNumber)
                    .fold(0, (max, e) => e > max ? e : max);
                _drawPages.add(DrawPageData(
                  pageNumber: maxNum + 1,
                  controller: DrawingController(),
                ));
              } else if (widget.currentTab == 2) {
                final maxNum = _whiteboardPages
                    .map((p) => p.pageNumber)
                    .fold(0, (max, e) => e > max ? e : max);
                _whiteboardPages.add(WhiteboardPageData(
                  pageNumber: maxNum + 1,
                  items: [],
                ));
              }
              _sortPages();
            });
          },
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: const Text('Add Page', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC73024),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildPageCard({
    required int pageNumber,
    required Function(int) onPageNumberChanged,
    required VoidCallback? onDelete,
    required Widget child,
  }) {
    final numberController = TextEditingController(text: pageNumber.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Page Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Text(
                  'Page ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: SmartNotesTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 50,
                  height: 24,
                  child: TextField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: SmartNotesTheme.textMain,
                    ),
                    enabled: widget.isEditMode,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(),
                      enabledBorder:
                          OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: SmartNotesTheme.accentBlue)),
                    ),
                    onSubmitted: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) {
                        onPageNumberChanged(parsed);
                      }
                    },
                  ),
                ),
                const Spacer(),
                if (onDelete != null && widget.isEditMode)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    onPressed: onDelete,
                    tooltip: 'Delete Page',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Attribute _unsetAttribute(Attribute attr) {
    return Attribute(attr.key, attr.scope, null);
  }

  void _toggleInline(QuillController controller, Attribute attr) {
    final sel = controller.selection;
    if (!sel.isValid || sel.isCollapsed || sel.start == sel.end) return;
    final index = sel.start;
    final len = sel.end - index;
    final attrs = controller.getSelectionStyle().attributes;
    if (attrs.containsKey(attr.key)) {
      controller.formatText(index, len, _unsetAttribute(attr));
    } else {
      controller.formatText(index, len, attr);
    }
  }

  void _applyBlock(QuillController controller, Attribute attr) {
    final sel = controller.selection;
    if (!sel.isValid || sel.isCollapsed || sel.start == sel.end) return;
    controller.formatText(sel.start, sel.end - sel.start, attr);
  }

  Widget _buildRichToolbar() {
    if (_textPages.isEmpty) return const SizedBox.shrink();
    final activeController = _textPages[_focusedPageIndex].controller;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: SmartNotesTheme.bgSecondary,
        border: Border(bottom: BorderSide(color: SmartNotesTheme.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _quillToolbarBtn(Icons.format_bold, () => _toggleInline(activeController, Attribute.bold)),
            const SizedBox(width: 4),
            _quillToolbarBtn(
                Icons.format_italic, () => _toggleInline(activeController, Attribute.italic)),
            const SizedBox(width: 4),
            _quillToolbarBtn(
                Icons.format_underline, () => _toggleInline(activeController, Attribute.underline)),
            const SizedBox(width: 4),
            _quillToolbarBtn(Icons.format_strikethrough,
                () => _toggleInline(activeController, Attribute.strikeThrough)),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: SmartNotesTheme.border),
            const SizedBox(width: 12),
            _quillToolbarBtn(
                Icons.format_list_bulleted, () => _toggleInline(activeController, Attribute.ul)),
            const SizedBox(width: 4),
            _quillToolbarBtn(
                Icons.format_list_numbered, () => _toggleInline(activeController, Attribute.ol)),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: SmartNotesTheme.border),
            const SizedBox(width: 12),
            _quillToolbarBtn(
                Icons.format_align_left, () => _applyBlock(activeController, Attribute.leftAlignment)),
            const SizedBox(width: 4),
            _quillToolbarBtn(Icons.format_align_center,
                () => _applyBlock(activeController, Attribute.centerAlignment)),
            const SizedBox(width: 4),
            _quillToolbarBtn(Icons.format_align_right,
                () => _applyBlock(activeController, Attribute.rightAlignment)),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: SmartNotesTheme.border),
            const SizedBox(width: 12),
            _quillToolbarBtn(
                Icons.format_quote, () => _toggleInline(activeController, Attribute.blockQuote)),
            const SizedBox(width: 4),
            _quillToolbarBtn(Icons.code, () => _toggleInline(activeController, Attribute.inlineCode)),
            const SizedBox(width: 4),
            _quillToolbarBtn(Icons.title, () => _toggleInline(activeController, Attribute.h1)),
            const SizedBox(width: 4),
            _quillToolbarBtn(
                Icons.text_fields, () => _toggleInline(activeController, Attribute.h2)),
            const SizedBox(width: 16),
            _quillToolbarBtn(Icons.color_lens_outlined, () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  backgroundColor: SmartNotesTheme.bgSecondary,
                  title: const Text('Choose Color', style: TextStyle(color: SmartNotesTheme.textMain)),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        _applyBlock(activeController,
                            Attribute('color', AttributeScope.inline, 'red'));
                        Navigator.pop(ctx);
                      },
                      child: const Row(children: [
                        Icon(Icons.circle, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Red', style: TextStyle(color: SmartNotesTheme.textMain)),
                      ]),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        _applyBlock(activeController,
                            Attribute('color', AttributeScope.inline, 'blue'));
                        Navigator.pop(ctx);
                      },
                      child: const Row(children: [
                        Icon(Icons.circle, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Blue', style: TextStyle(color: SmartNotesTheme.textMain)),
                      ]),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        _applyBlock(activeController,
                            Attribute('color', AttributeScope.inline, 'green'));
                        Navigator.pop(ctx);
                      },
                      child: const Row(children: [
                        Icon(Icons.circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Green', style: TextStyle(color: SmartNotesTheme.textMain)),
                      ]),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        _applyBlock(activeController,
                            Attribute('color', AttributeScope.inline, 'purple'));
                        Navigator.pop(ctx);
                      },
                      child: const Row(children: [
                        Icon(Icons.circle, color: Colors.purple, size: 20),
                        SizedBox(width: 8),
                        Text('Purple', style: TextStyle(color: SmartNotesTheme.textMain)),
                      ]),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _quillToolbarBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: SmartNotesTheme.iconActive, size: 18),
      ),
    );
  }

  Widget _buildTabBtn(String title, IconData icon, int index) {
    bool isActive = widget.currentTab == index;
    return GestureDetector(
      onTap: () => widget.onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? SmartNotesTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(SmartNotesTheme.radiusSmall),
          border: Border.all(
            color: isActive ? Colors.transparent : SmartNotesTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? SmartNotesTheme.iconDark : SmartNotesTheme.iconColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isActive ? SmartNotesTheme.textDark : SmartNotesTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiTabBtn(String title, IconData icon) {
    bool isActive = widget.isAiVisible;
    return GestureDetector(
      onTap: () {
        widget.onAiVisibleChanged(true);
        widget.onTabChanged(1); // Auto switch to Draw tab
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? SmartNotesTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(SmartNotesTheme.radiusSmall),
          border: Border.all(
            color: isActive ? Colors.transparent : SmartNotesTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? SmartNotesTheme.iconDark : SmartNotesTheme.iconColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isActive ? SmartNotesTheme.textDark : SmartNotesTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: SmartNotesTheme.bgTertiary,
          borderRadius: BorderRadius.circular(SmartNotesTheme.radiusSmall),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Row(
          children: [
            Icon(icon, color: SmartNotesTheme.iconActive, size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: SmartNotesTheme.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemovableTag(String text, bool isEditMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SmartNotesTheme.bgTertiary,
        borderRadius: BorderRadius.circular(SmartNotesTheme.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: SmartNotesTheme.caption.copyWith(color: SmartNotesTheme.textMain),
          ),
          if (isEditMode) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _removeTag(text),
              child: const Icon(Icons.close, color: SmartNotesTheme.iconColor, size: 12),
            ),
          ]
        ],
      ),
    );
  }

  // --- SCREEN LEVEL COLLAPSIBLE SIDEBARS HELPERS ---
  final List<Map<String, dynamic>> _graphsAndShapes = [
    {'name': 'axes', 'label': 'Axes Grid', 'icon': Icons.grid_4x4, 'category': 'Graphs'},
    {'name': 'sine', 'label': 'Sine Wave', 'icon': Icons.waves, 'category': 'Graphs'},
    {'name': 'cosine', 'label': 'Cosine Wave', 'icon': Icons.gesture, 'category': 'Graphs'},
    {'name': 'parabola', 'label': 'Parabola', 'icon': Icons.show_chart, 'category': 'Graphs'},
    {'name': 'bell', 'label': 'Normal Curve', 'icon': Icons.trending_up, 'category': 'Graphs'},
    {'name': 'exponential', 'label': 'Exponential', 'icon': Icons.timeline, 'category': 'Graphs'},
    {'name': 'cube', 'label': '3D Cube', 'icon': Icons.view_in_ar, 'category': 'Shapes'},
    {'name': 'cylinder', 'label': 'Cylinder', 'icon': Icons.filter_hdr, 'category': 'Shapes'},
    {'name': 'sphere', 'label': 'Sphere', 'icon': Icons.blur_on, 'category': 'Shapes'},
    {'name': 'human', 'label': 'Human Stick', 'icon': Icons.accessibility_new, 'category': 'Shapes'},
    {'name': 'database', 'label': 'Database', 'icon': Icons.storage, 'category': 'CSE Icons'},
    {'name': 'laptop', 'label': 'Laptop', 'icon': Icons.laptop_mac, 'category': 'CSE Icons'},
    {'name': 'cloud', 'label': 'Cloud Storage', 'icon': Icons.cloud_queue, 'category': 'CSE Icons'},
    {'name': 'code', 'label': 'Code Box', 'icon': Icons.code, 'category': 'CSE Icons'},
    {'name': 'network', 'label': 'Network Nodes', 'icon': Icons.hub, 'category': 'CSE Icons'},
    {'name': 'server', 'label': 'Server Rack', 'icon': Icons.dns, 'category': 'CSE Icons'},
  ];

  final List<Map<String, dynamic>> _tablesAndFlow = [
    {'name': 'table_classic', 'label': 'Classic DB Table', 'icon': Icons.table_chart, 'category': 'DB Tables'},
    {'name': 'table_data', 'label': 'Data Grid Table', 'icon': Icons.grid_on, 'category': 'DB Tables'},
    {'name': 'uml_class', 'label': 'UML Class diagram', 'icon': Icons.schema, 'category': 'UML / Programming'},
    {'name': 'flow_start', 'label': 'Flow Start / End', 'icon': Icons.change_history, 'category': 'Flowchart'},
    {'name': 'flow_process', 'label': 'Flow Process', 'icon': Icons.crop_din, 'category': 'Flowchart'},
    {'name': 'flow_decision', 'label': 'Flow Decision', 'icon': Icons.diamond, 'category': 'Flowchart'},
  ];

  final List<Map<String, String>> _mathPhysicsConstants = [
    {'name': 'Speed of Light (c)', 'val': '3.00 × 10⁸ m/s'},
    {'name': 'Gravity acceleration (g)', 'val': '9.81 m/s²'},
    {'name': 'Planck Constant (h)', 'val': '6.626 × 10⁻³⁴ J·s'},
    {'name': 'Universal Gas (R)', 'val': '8.314 J/(mol·K)'},
    {'name': 'Euler\'s Number (e)', 'val': '2.71828'},
    {'name': 'Ratio Pi (π)', 'val': '3.14159'},
  ];

  Widget _buildSidebarToggle({required bool isLeft, required bool isExpanded, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 14,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SmartNotesTheme.bgTertiary,
          border: Border.all(color: SmartNotesTheme.border),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(isLeft ? 6 : 0),
            bottomRight: Radius.circular(isLeft ? 6 : 0),
            topLeft: Radius.circular(isLeft ? 0 : 6),
            bottomLeft: Radius.circular(isLeft ? 0 : 6),
          ),
        ),
        child: Icon(
          isLeft
              ? (isExpanded ? Icons.chevron_left : Icons.chevron_right)
              : (isExpanded ? Icons.chevron_right : Icons.chevron_left),
          size: 11,
          color: SmartNotesTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildLeftSidebarContent() {
    final int tab = widget.currentTab.clamp(0, 2);
    if (tab == 0) {
      return _buildTextLeftSidebar();
    } else if (tab == 1) {
      return _buildDrawLeftSidebar();
    } else {
      return _buildWhiteboardLeftSidebar();
    }
  }

  Widget _buildRightSidebarContent() {
    final int tab = widget.currentTab.clamp(0, 2);
    if (tab == 0) {
      return _buildTextRightSidebar();
    } else if (tab == 1) {
      return _buildDrawRightSidebar();
    } else {
      return _buildWhiteboardRightSidebar();
    }
  }

  // --- TEXT TAB SIDEBARS ---
  void _insertColorHeader(QuillController controller, String hexColor) {
    final index = controller.selection.baseOffset;
    controller.document.insert(index, '\n📖 HEADER BANNER\n');
    controller.formatText(index + 1, 17, Attribute.h2);
    controller.formatText(index + 1, 17, Attribute.bold);
    controller.formatText(index + 1, 17, Attribute('background', AttributeScope.inline, hexColor));
    controller.formatText(index + 1, 17, Attribute('color', AttributeScope.inline, '#FFFFFF'));
  }

  Widget _buildTextLeftSidebar() {
    if (_textPages.isEmpty) return const SizedBox.shrink();
    final activePage = _textPages[_focusedPageIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: SmartNotesTheme.bgTertiary,
          child: const Text('Text Elements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildSidebarBtn(
                icon: Icons.title,
                label: 'Title Block',
                onTap: () {
                  final controller = activePage.controller;
                  final index = controller.selection.baseOffset;
                  controller.document.insert(index, '\n✍️ Title\n');
                  controller.formatText(index + 1, 8, Attribute.h1);
                  controller.formatText(index + 1, 8, Attribute.bold);
                },
              ),
              const SizedBox(height: 12),
              const Text('Header Banners', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SmartNotesTheme.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildColorHeaderBtn('Blue Banner', Colors.blue, () {
                    _insertColorHeader(activePage.controller, '#3B82F6');
                  }),
                  _buildColorHeaderBtn('Green Banner', Colors.green, () {
                    _insertColorHeader(activePage.controller, '#10B981');
                  }),
                  _buildColorHeaderBtn('Orange Banner', Colors.orange, () {
                    _insertColorHeader(activePage.controller, '#F59E0B');
                  }),
                ],
              ),
              const SizedBox(height: 16),
              _buildSidebarBtn(
                icon: Icons.push_pin_outlined,
                label: 'Side Note Card',
                onTap: () {
                  final controller = activePage.controller;
                  final index = controller.selection.baseOffset;
                  controller.document.insert(index, '\n📌 Note: Enter reference info here...\n');
                  controller.formatText(index + 1, 36, Attribute.blockQuote);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextRightSidebar() {
    if (_textPages.isEmpty) return const SizedBox.shrink();
    final activePage = _textPages[_focusedPageIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: SmartNotesTheme.bgTertiary,
          child: const Text('Outline & Styles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text('Document Outline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SmartNotesTheme.textMuted)),
              const SizedBox(height: 8),
              _buildDocOutlineList(activePage.controller),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocOutlineList(QuillController controller) {
    final List<Map<String, dynamic>> outlines = [];
    final doc = controller.document;
    final delta = doc.toDelta();
    int offset = 0;
    for (var op in delta.operations) {
      if (op.isInsert && op.data is String) {
        final text = op.data as String;
        if (op.attributes != null) {
          final attr = op.attributes!;
          if (attr.containsKey('header')) {
            final level = attr['header'];
            outlines.add({
              'text': text.trim(),
              'offset': offset,
              'level': level,
            });
          }
        }
        offset += text.length;
      } else {
        offset += (op.length ?? 0);
      }
    }

    if (outlines.isEmpty) {
      return const Text('No headers found. Format lines as Title or Banner.', style: TextStyle(fontSize: 10, color: SmartNotesTheme.textMuted));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: outlines.map((o) {
        final double paddingLeft = (o['level'] == 1) ? 0.0 : 12.0;
        return InkWell(
          onTap: () {
            controller.updateSelection(
              TextSelection.collapsed(offset: o['offset']),
              ChangeSource.local,
            );
          },
          child: Padding(
            padding: EdgeInsets.only(left: paddingLeft, bottom: 6.0),
            child: Text(
              o['text'],
              style: TextStyle(
                fontSize: 11,
                fontWeight: o['level'] == 1 ? FontWeight.bold : FontWeight.normal,
                color: SmartNotesTheme.accentBlue,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSidebarBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: SmartNotesTheme.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: SmartNotesTheme.accentBlue),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SmartNotesTheme.textMain)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorHeaderBtn(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- DRAW TAB SIDEBARS ---
  Widget _buildDrawLeftSidebar() {
    if (_drawPages.isEmpty) return const SizedBox.shrink();
    final activePage = _drawPages[_focusedDrawPageIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: SmartNotesTheme.border)),
            color: SmartNotesTheme.bgTertiary,
          ),
          child: const Text(
            'Ready Drawables',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SmartNotesTheme.textMain),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              _buildSectionTitle('Engineering Graphs'),
              _buildPrefabGrid('Graphs', activePage.controller),
              const SizedBox(height: 16),
              _buildSectionTitle('Geometric Shapes'),
              _buildPrefabGrid('Shapes', activePage.controller),
              const SizedBox(height: 16),
              _buildSectionTitle('CSE Diagrams & Nodes'),
              _buildPrefabGrid('CSE Icons', activePage.controller),
              const SizedBox(height: 16),
              _buildSectionTitle('Database Tables'),
              _buildPrefabList('DB Tables', activePage.controller),
              const SizedBox(height: 16),
              _buildSectionTitle('UML Diagrams'),
              _buildPrefabList('UML / Programming', activePage.controller),
              const SizedBox(height: 16),
              _buildSectionTitle('Flowchart Elements'),
              _buildPrefabGrid('Flowchart', activePage.controller, isRightSide: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawRightSidebar() {
    return const SizedBox.shrink();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SmartNotesTheme.textMuted),
      ),
    );
  }

  Widget _buildPrefabGrid(String category, DrawingController controller, {bool isRightSide = false}) {
    final list = isRightSide
        ? _tablesAndFlow.where((e) => e['category'] == category).toList()
        : _graphsAndShapes.where((e) => e['category'] == category).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final item = list[i];
        return _buildDraggablePrefabItem(item['name'], item['icon'], item['label'], controller);
      },
    );
  }

  Widget _buildPrefabList(String category, DrawingController controller) {
    final list = _tablesAndFlow.where((e) => e['category'] == category).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = list[i];
        return GestureDetector(
          onTap: () => controller.addPrefabStroke(item['name']),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: SmartNotesTheme.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(item['icon'], size: 16, color: SmartNotesTheme.accentBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['label'],
                    style: const TextStyle(fontSize: 11, color: SmartNotesTheme.textMain, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggablePrefabItem(String name, IconData icon, String label, DrawingController controller) {
    return GestureDetector(
      onTap: () => controller.addPrefabStroke(name),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: SmartNotesTheme.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: SmartNotesTheme.textMuted),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                label,
                style: const TextStyle(fontSize: 9, color: SmartNotesTheme.textMain, height: 1.1),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WHITEBOARD TAB SIDEBARS ---
  void _addWhiteboardTemplate(String type) {
    if (_whiteboardPages.isEmpty) return;
    final activePage = _whiteboardPages[_focusedWhiteboardPageIndex];
    final uuid = const Uuid();
    String content = '';
    Color color = Colors.yellow.shade100;
    double w = 220.0;
    double h = 180.0;

    if (type == 'planner') {
      content = '📅 STUDY PLANNER\n\n• Sub 1: Read chapter 3\n• Sub 2: Complete lab report\n• Sub 3: Solve practice questions\n• Review: Group discussion 6pm';
      color = Colors.green.shade100;
      w = 240.0;
      h = 200.0;
    } else if (type == 'formula') {
      content = '🧪 PHYSICS CONSTANTS & EQ\n\n• F = m * a\n• E = m * c²\n• v = u + a * t\n• Gravity (g) = 9.81 m/s²\n• Planck (h) = 6.63e-34 J·s';
      color = Colors.blue.shade100;
      w = 240.0;
      h = 190.0;
    } else if (type == 'code') {
      content = '💻 ALGORITHM / CODE\n\nfunction search(arr, x) {\n  let l = 0, r = arr.length-1;\n  while (l <= r) {\n    let m = Math.floor((l+r)/2);\n    if (arr[m] === x) return m;\n  }\n  return -1;\n}';
      color = Colors.grey.shade100;
      w = 260.0;
      h = 220.0;
    } else if (type == 'todo') {
      content = '📝 TODAY\'S TASKLIST\n\n[ ] Complete math exercises\n[ ] Write literature draft\n[ ] Review compiler stages\n[ ] Commit local changes';
      color = Colors.yellow.shade100;
      w = 220.0;
      h = 180.0;
    }

    setState(() {
      activePage.items.add(WhiteboardItem(
        id: uuid.v4(),
        position: const Offset(120, 120),
        type: 'clip',
        content: content,
        colorValue: color.value,
        width: w,
        height: h,
      ));
    });
  }

  Widget _buildWhiteboardLeftSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: SmartNotesTheme.border)),
            color: SmartNotesTheme.bgTertiary,
          ),
          child: const Text(
            'Study Templates',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SmartNotesTheme.textMain),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildTemplateCard('planner', Icons.date_range, 'Study Planner', 'Track exams & daily targets'),
              const SizedBox(height: 12),
              _buildTemplateCard('formula', Icons.functions, 'Formula Card', 'Write equations & metrics'),
              const SizedBox(height: 12),
              _buildTemplateCard('code', Icons.terminal, 'Code Snippet', 'Template for algorithms'),
              const SizedBox(height: 12),
              _buildTemplateCard('todo', Icons.checklist, 'Todo Checklist', 'Mark items complete'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(String type, IconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: () => _addWhiteboardTemplate(type),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: SmartNotesTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SmartNotesTheme.bgTertiary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: SmartNotesTheme.accentBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SmartNotesTheme.textMain)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: SmartNotesTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteboardRightSidebar() {
    if (_whiteboardPages.isEmpty) return const SizedBox.shrink();
    final activePage = _whiteboardPages[_focusedWhiteboardPageIndex];
    final String minutes = (_pomodoroSeconds ~/ 60).toString().padLeft(2, '0');
    final String seconds = (_pomodoroSeconds % 60).toString().padLeft(2, '0');
    final uuid = const Uuid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: SmartNotesTheme.border)),
            color: SmartNotesTheme.bgTertiary,
          ),
          child: const Text(
            'Study Companion',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SmartNotesTheme.textMain),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Pomodoro Timer Widget
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: SmartNotesTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pomodoro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SmartNotesTheme.textMain)),
                        Icon(Icons.timer_outlined, size: 14, color: _isBreakTime ? Colors.green : Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$minutes:$seconds',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: _isBreakTime ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isBreakTime ? 'Break Time!' : 'Work Session',
                      style: const TextStyle(fontSize: 10, color: SmartNotesTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _isPomodoroRunning ? _pausePomodoro : _startPomodoro,
                          icon: Icon(_isPomodoroRunning ? Icons.pause_circle_outline : Icons.play_circle_outline),
                          iconSize: 22,
                          color: SmartNotesTheme.accentBlue,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          onPressed: _resetPomodoro,
                          icon: const Icon(Icons.replay),
                          iconSize: 20,
                          color: SmartNotesTheme.textMuted,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              // Reference Constants Widget
              const Padding(
                padding: EdgeInsets.only(bottom: 6.0),
                child: Text('Academic Constants', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SmartNotesTheme.textMuted)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: SmartNotesTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _mathPhysicsConstants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: SmartNotesTheme.border),
                  itemBuilder: (context, idx) {
                    final item = _mathPhysicsConstants[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name']!, style: const TextStyle(fontSize: 10, color: SmartNotesTheme.textMuted)),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['val']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SmartNotesTheme.textMain)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 12),
                                onPressed: () {
                                  setState(() {
                                    activePage.items.add(WhiteboardItem(
                                      id: uuid.v4(),
                                      position: const Offset(150, 150),
                                      type: 'text_box',
                                      content: '${item['name']}: ${item['val']}',
                                      colorValue: Colors.transparent.value,
                                      width: 180.0,
                                      height: 60.0,
                                    ));
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Add as TextBox',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startPomodoro() {
    if (_isPomodoroRunning) return;
    setState(() {
      _isPomodoroRunning = true;
    });
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pomodoroSeconds > 0) {
        setState(() {
          _pomodoroSeconds--;
        });
      } else {
        _timerFinished();
      }
    });
  }

  void _pausePomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
    });
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _pomodoroSeconds = _isBreakTime ? 5 * 60 : 25 * 60;
    });
  }

  void _timerFinished() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _isBreakTime = !_isBreakTime;
      _pomodoroSeconds = _isBreakTime ? 5 * 60 : 25 * 60;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBreakTime ? 'Time for a break! ☕' : 'Break over, back to work! 🚀'),
        backgroundColor: SmartNotesTheme.accentBlue,
      ),
    );
  }
}

class TableEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'table';

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final markdown = embedContext.node.value.data as String;
    final parsed = parseMarkdownTable(markdown);
    if (parsed == null) return Text(markdown);

    final headers = parsed['headers'] as List<String>;
    final rows = parsed['rows'] as List<List<String>>;
    final double width = parsed['width'] as double;

    return EditableTableWidget(
      headers: headers,
      rows: rows,
      initialWidth: width,
      readOnly: embedContext.readOnly,
      onTableChanged: (updatedMarkdown) {
        final offset = embedContext.node.documentOffset;
        embedContext.controller.replaceText(
          offset,
          1,
          BlockEmbed('table', updatedMarkdown),
          null,
        );
      },
    );
  }
}

class Base64ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final imageUrl = embedContext.node.value.data as String;
    if (imageUrl.startsWith('data:image/')) {
      try {
        final cleanBase64 = imageUrl.split(',').last;
        final bytes = base64Decode(cleanBase64);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
          ),
        );
      } catch (e) {
        return Text('Error rendering image: $e');
      }
    }
    
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        errorBuilder: (context, error, stackTrace) => Text('Failed to load image: $imageUrl'),
      );
    }
    
    return Text('Unsupported image source: $imageUrl');
  }
}
