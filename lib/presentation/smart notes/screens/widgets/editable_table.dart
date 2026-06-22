import 'package:flutter/material.dart';

Map<String, dynamic>? parseMarkdownTable(String text) {
  var cleanText = text.trim();
  double width = 500.0;
  
  if (cleanText.startsWith('[width:')) {
    final match = RegExp(r'^\[width:(\d+)\]\s*').firstMatch(cleanText);
    if (match != null) {
      width = double.tryParse(match.group(1)!) ?? 500.0;
      cleanText = cleanText.substring(match.end).trim();
    }
  }

  final lines = cleanText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.length < 2) return null;
  
  int linesWithPipe = lines.where((l) => l.contains('|')).length;
  if (linesWithPipe < lines.length * 0.6 || !lines.first.contains('|')) {
    return null;
  }
  
  final parsedRows = <List<String>>[];
  for (var line in lines) {
    final cleanLine = line.replaceAll(RegExp(r'[\|\-\:\s]'), '');
    if (cleanLine.isEmpty && line.contains('-')) {
      continue;
    }
    
    final List<String> cells = line.split('|').map((s) => s.trim()).toList();
    if (cells.first.isEmpty) cells.removeAt(0);
    if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();
    
    if (cells.isEmpty || (cells.length == 1 && cells[0].isEmpty)) continue;
    parsedRows.add(cells);
  }
  
  if (parsedRows.length < 2) return null;
  
  final headers = parsedRows.first;
  final rows = parsedRows.skip(1).toList();
  
  return {
    'headers': headers,
    'rows': rows,
    'width': width,
  };
}

class EditableTableWidget extends StatefulWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final double initialWidth;
  final bool readOnly;
  final Function(String) onTableChanged;
  final bool showBorder;
  final EdgeInsetsGeometry margin;

  const EditableTableWidget({
    super.key,
    required this.headers,
    required this.rows,
    required this.initialWidth,
    required this.readOnly,
    required this.onTableChanged,
    this.showBorder = true,
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  State<EditableTableWidget> createState() => _EditableTableWidgetState();
}

class _EditableTableWidgetState extends State<EditableTableWidget> {
  late double _width;
  late List<TextEditingController> _headerControllers;
  late List<List<TextEditingController>> _rowControllers;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
    _initControllers();
  }

  void _initControllers() {
    _headerControllers = widget.headers
        .map((h) => TextEditingController(text: h))
        .toList();
    _rowControllers = widget.rows
        .map((row) => row.map((cell) => TextEditingController(text: cell)).toList())
        .toList();
  }

  @override
  void didUpdateWidget(EditableTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWidth != widget.initialWidth) {
      _width = widget.initialWidth;
    }
    if (oldWidget.headers.length != widget.headers.length ||
        oldWidget.rows.length != widget.rows.length) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _disposeControllers() {
    for (var c in _headerControllers) {
      c.dispose();
    }
    for (var row in _rowControllers) {
      for (var c in row) {
        c.dispose();
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _triggerUpdate() {
    final buffer = StringBuffer();
    buffer.writeln('[width:${_width.toInt()}]');
    
    final headersList = _headerControllers.map((c) => c.text).toList();
    buffer.writeln(headersList.join(' | '));
    buffer.writeln(List.generate(headersList.length, (_) => '---').join(' | '));
    for (var row in _rowControllers) {
      final rowList = row.map((c) => c.text).toList();
      buffer.writeln(rowList.join(' | '));
    }
    widget.onTableChanged(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: widget.margin,
        width: _width,
        decoration: widget.showBorder
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              )
            : const BoxDecoration(
                color: Colors.white,
              ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.readOnly)
              Container(
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.line_weight, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('Width:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: _width.clamp(200.0, 800.0),
                          min: 200.0,
                          max: 800.0,
                          activeColor: const Color(0xFF3B82F6),
                          onChanged: (val) {
                            setState(() {
                              _width = val;
                            });
                          },
                          onChangeEnd: (val) {
                            _triggerUpdate();
                          },
                        ),
                      ),
                    ),
                    Text('${_width.toInt()}px', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(color: const Color(0xFFF3F4F6), width: 1),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                    ),
                    children: List.generate(_headerControllers.length, (colIdx) {
                      final controller = _headerControllers[colIdx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: widget.readOnly
                            ? Text(
                                controller.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                ),
                              )
                            : Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) _triggerUpdate();
                                },
                                child: IntrinsicWidth(
                                  child: TextField(
                                    controller: controller,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.5,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                      );
                    }),
                  ),
                  ...List.generate(_rowControllers.length, (rowIdx) {
                    final isOdd = rowIdx % 2 == 1;
                    final row = _rowControllers[rowIdx];
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isOdd ? const Color(0xFFF9FAFB) : Colors.white,
                      ),
                      children: List.generate(row.length, (colIdx) {
                        final controller = row[colIdx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: widget.readOnly
                              ? Text(
                                  controller.text,
                                  style: const TextStyle(
                                    color: Color(0xFF374151),
                                    fontSize: 9.5,
                                  ),
                                )
                              : Focus(
                                  onFocusChange: (hasFocus) {
                                    if (!hasFocus) _triggerUpdate();
                                  },
                                  child: TextField(
                                    controller: controller,
                                    style: const TextStyle(
                                      color: Color(0xFF374151),
                                      fontSize: 9.5,
                                    ),
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
