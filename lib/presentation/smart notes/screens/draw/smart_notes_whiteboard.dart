import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';
import '../widgets/editable_table.dart';

class WhiteboardItem {
  final String id;
  Offset position;
  final String type; // 'sticky_note', 'clip', or 'text_box'
  String content;
  int colorValue;
  double fontSize;
  double width;
  double? height;

  WhiteboardItem({
    required this.id,
    required this.position,
    required this.type,
    this.content = '',
    required this.colorValue,
    this.fontSize = 15.0,
    this.width = 220.0,
    this.height,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': position.dx,
        'y': position.dy,
        'type': type,
        'content': content,
        'colorValue': colorValue,
        'fontSize': fontSize,
        'width': width,
        'height': height,
      };

  factory WhiteboardItem.fromJson(Map<String, dynamic> json) {
    return WhiteboardItem(
      id: json['id'] ?? const Uuid().v4(),
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 50.0,
        (json['y'] as num?)?.toDouble() ?? 50.0,
      ),
      type: json['type'] ?? 'sticky_note',
      content: json['content'] ?? '',
      colorValue: json['colorValue'] ?? Colors.amber.shade100.value,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 15.0,
      width: (json['width'] as num?)?.toDouble() ?? 220.0,
      height: (json['height'] as num?)?.toDouble(),
    );
  }
}

class SmartNotesWhiteboard extends StatefulWidget {
  final List<WhiteboardItem> items;
  final bool isEditMode;
  final VoidCallback onChanged;

  const SmartNotesWhiteboard({
    super.key,
    required this.items,
    required this.isEditMode,
    required this.onChanged,
  });

  @override
  State<SmartNotesWhiteboard> createState() => _SmartNotesWhiteboardState();
}

class _SmartNotesWhiteboardState extends State<SmartNotesWhiteboard> {
  final _uuid = const Uuid();
  bool _isLeftPanelExpanded = true;
  bool _isRightPanelExpanded = true;

  // Pomodoro timer state
  Timer? _pomodoroTimer;
  int _pomodoroSeconds = 25 * 60;
  bool _isPomodoroRunning = false;
  bool _isBreakTime = false;

  final List<Map<String, String>> _constants = [
    {'name': 'Speed of Light (c)', 'val': '3.00 × 10⁸ m/s'},
    {'name': 'Gravity acceleration (g)', 'val': '9.81 m/s²'},
    {'name': 'Planck Constant (h)', 'val': '6.626 × 10⁻³⁴ J·s'},
    {'name': 'Universal Gas (R)', 'val': '8.314 J/(mol·K)'},
    {'name': 'Euler\'s Number (e)', 'val': '2.71828'},
    {'name': 'Ratio Pi (π)', 'val': '3.14159'},
  ];

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    super.dispose();
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

  void _addStickyNote() {
    setState(() {
      widget.items.add(WhiteboardItem(
        id: _uuid.v4(),
        position: const Offset(100, 100),
        type: 'sticky_note',
        content: 'New Sticky Note\nDouble-tap to edit',
        colorValue: Colors.yellow.shade100.value,
        width: 220.0,
        height: null,
      ));
    });
    widget.onChanged();
  }

  void _addNoteClip() {
    setState(() {
      widget.items.add(WhiteboardItem(
        id: _uuid.v4(),
        position: const Offset(150, 150),
        type: 'clip',
        content: 'Clipped Note\nDouble-tap to edit content',
        colorValue: Colors.blue.shade50.value,
        width: 250.0,
        height: null,
      ));
    });
    widget.onChanged();
  }

  void _addTextBox() {
    setState(() {
      widget.items.add(WhiteboardItem(
        id: _uuid.v4(),
        position: const Offset(200, 200),
        type: 'text_box',
        content: 'Manual Text Box\nDouble-tap to write',
        colorValue: Colors.transparent.value,
        width: 180.0,
        height: null,
      ));
    });
    widget.onChanged();
  }

  void _addTemplate(String type) {
    String content = '';
    Color color = Colors.yellow.shade100;
    double w = 220.0;

    if (type == 'planner') {
      content = '📅 STUDY PLANNER\n\n• Sub 1: Read chapter 3\n• Sub 2: Complete lab report\n• Sub 3: Solve practice questions\n• Review: Group discussion 6pm';
      color = Colors.green.shade100;
      w = 240.0;
    } else if (type == 'formula') {
      content = '🧪 PHYSICS CONSTANTS & EQ\n\n• F = m * a\n• E = m * c²\n• v = u + a * t\n• Gravity (g) = 9.81 m/s²\n• Planck (h) = 6.63e-34 J·s';
      color = Colors.blue.shade100;
      w = 240.0;
    } else if (type == 'code') {
      content = '💻 ALGORITHM / CODE\n\nfunction search(arr, x) {\n  let l = 0, r = arr.length-1;\n  while (l <= r) {\n    let m = Math.floor((l+r)/2);\n    if (arr[m] === x) return m;\n  }\n  return -1;\n}';
      color = Colors.grey.shade100;
      w = 260.0;
    } else if (type == 'todo') {
      content = '📝 TODAY\'S TASKLIST\n\n[ ] Complete math exercises\n[ ] Write literature draft\n[ ] Review compiler stages\n[ ] Commit local changes';
      color = Colors.yellow.shade100;
      w = 220.0;
    }

    setState(() {
      widget.items.add(WhiteboardItem(
        id: _uuid.v4(),
        position: const Offset(120, 120),
        type: 'clip',
        content: content,
        colorValue: color.value,
        width: w,
        height: null,
      ));
    });
    widget.onChanged();
  }

  void _editItemContent(WhiteboardItem item) {
    TextEditingController controller = TextEditingController(text: item.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SmartNotesTheme.bgSecondary,
        title: Text(
          item.type == 'sticky_note'
              ? 'Edit Sticky Note'
              : (item.type == 'clip' ? 'Edit Clipped Note' : 'Edit Text Box'),
          style: const TextStyle(color: SmartNotesTheme.textMain, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 6,
          style: SmartNotesTheme.body,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: SmartNotesTheme.border)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: SmartNotesTheme.accentBlue)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: SmartNotesTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SmartNotesTheme.accentBlue),
            onPressed: () {
              setState(() {
                item.content = controller.text;
              });
              Navigator.pop(ctx);
              widget.onChanged();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _bringToFront(WhiteboardItem item) {
    setState(() {
      widget.items.remove(item);
      widget.items.add(item);
    });
    widget.onChanged();
  }

  void _changeColor(WhiteboardItem item) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: SmartNotesTheme.bgSecondary,
        title: const Text('Change Background Color', style: TextStyle(color: SmartNotesTheme.textMain)),
        children: [
          if (item.type == 'text_box')
            _colorOption(item, Colors.transparent, 'Transparent', ctx),
          _colorOption(item, Colors.yellow.shade100, 'Yellow', ctx),
          _colorOption(item, Colors.green.shade100, 'Green', ctx),
          _colorOption(item, Colors.blue.shade100, 'Blue', ctx),
          _colorOption(item, Colors.pink.shade100, 'Pink', ctx),
          _colorOption(item, Colors.purple.shade100, 'Purple', ctx),
          _colorOption(item, Colors.orange.shade100, 'Orange', ctx),
        ],
      ),
    );
  }

  SimpleDialogOption _colorOption(
      WhiteboardItem item, Color color, String name, BuildContext ctx) {
    return SimpleDialogOption(
      onPressed: () {
        setState(() => item.colorValue = color.value);
        Navigator.pop(ctx);
        widget.onChanged();
      },
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: SmartNotesTheme.textMain)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isEditMode) _buildToolbar(),
        Expanded(
          child: Container(
            color: Colors.grey.shade100,
            child: Stack(
              children: [
                ...widget.items.map((item) => Positioned(
                      left: item.position.dx,
                      top: item.position.dy,
                      width: item.width,
                      height: item.height,
                      child: GestureDetector(
                        onPanUpdate: widget.isEditMode
                            ? (details) {
                                setState(() {
                                  item.position += details.delta;
                                });
                              }
                            : null,
                        onPanStart: widget.isEditMode ? (_) => _bringToFront(item) : null,
                        onDoubleTap: widget.isEditMode ? () => _editItemContent(item) : null,
                        child: _buildItem(item),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: SmartNotesTheme.bgMain,
        border: Border(bottom: BorderSide(color: SmartNotesTheme.border)),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _addStickyNote,
            icon: const Icon(Icons.sticky_note_2, size: 16, color: Colors.white),
            label: const Text('Add Sticky Note', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC73024),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _addNoteClip,
            icon: const Icon(Icons.push_pin, size: 16, color: Colors.white),
            label: const Text('Clip Note Card', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE29F5C),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _addTextBox,
            icon: const Icon(Icons.title, size: 16, color: Colors.white),
            label: const Text('Text Box', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: SmartNotesTheme.accentBlue,
              elevation: 0,
            ),
          ),
          const Spacer(),
          const Text(
            'Double-tap item to edit content • Drag corner to resize',
            style: TextStyle(color: SmartNotesTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(WhiteboardItem item) {
    if (item.type == 'image') {
      final isBase64 = item.content.startsWith('data:image/');
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: item.width,
            height: item.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: isBase64
                  ? Image.memory(
                      base64Decode(item.content.split(',').last),
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      item.content,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.redAccent),
                      ),
                    ),
            ),
          ),
          if (widget.isEditMode)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    widget.items.remove(item);
                  });
                  widget.onChanged();
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          // Drag resize handle at bottom-right corner
          if (widget.isEditMode)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: (details) {
                  if (item.height == null) {
                    setState(() {
                      item.height = 160.0;
                    });
                  }
                },
                onPanUpdate: (details) {
                  setState(() {
                    item.width = (item.width + details.delta.dx).clamp(120.0, 800.0);
                    if (item.height != null) {
                      item.height = (item.height! + details.delta.dy).clamp(60.0, 800.0);
                    }
                  });
                },
                onPanEnd: (_) {
                  widget.onChanged();
                },
                child: const MouseRegion(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.filter_list,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    } else if (item.type == 'table') {
      final parsed = parseMarkdownTable(item.content);
      Widget tableWidget;
      if (parsed == null) {
        tableWidget = Center(child: Text(item.content));
      } else {
        final headers = parsed['headers'] as List<String>;
        final rows = parsed['rows'] as List<List<String>>;
        tableWidget = EditableTableWidget(
          headers: headers,
          rows: rows,
          initialWidth: item.width,
          readOnly: !widget.isEditMode,
          showBorder: false,
          margin: EdgeInsets.zero,
          onTableChanged: (updatedMarkdown) {
            setState(() {
              item.content = updatedMarkdown;
              final reParsed = parseMarkdownTable(updatedMarkdown);
              if (reParsed != null && reParsed['width'] != null) {
                item.width = reParsed['width'];
              }
            });
            widget.onChanged();
          },
        );
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: item.width,
            height: item.height,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Column(
                children: [
                  // Drag Handle Bar at top
                  Container(
                    color: const Color(0xFFF3F4F6),
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.drag_indicator, size: 14, color: Colors.black45),
                        const SizedBox(width: 4),
                        const Text(
                          'Table',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (widget.isEditMode)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                widget.items.remove(item);
                              });
                              widget.onChanged();
                            },
                            child: const Icon(Icons.close, size: 14, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                  // Table Content Area
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: tableWidget,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isEditMode)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: (details) {
                  if (item.height == null) {
                    setState(() {
                      item.height = 160.0;
                    });
                  }
                },
                onPanUpdate: (details) {
                  setState(() {
                    item.width = (item.width + details.delta.dx).clamp(120.0, 800.0);
                    if (item.height != null) {
                      item.height = (item.height! + details.delta.dy).clamp(60.0, 800.0);
                    }
                  });
                },
                onPanEnd: (_) {
                  widget.onChanged();
                },
                child: const MouseRegion(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.filter_list,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    bool isClip = item.type == 'clip';
    bool isTextBox = item.type == 'text_box';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Board Container (Determines natural height if item.height is null)
        Container(
          width: item.width,
          height: item.height,
          margin: EdgeInsets.only(top: isClip ? 20.0 : 0.0),
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 12,
            top: isClip ? 24 : 12,
          ),
          decoration: BoxDecoration(
            color: isTextBox
                ? (item.colorValue == Colors.transparent.value
                    ? Colors.transparent
                    : item.color)
                : item.color,
            borderRadius: BorderRadius.circular(isTextBox ? 4.0 : (isClip ? 8.0 : 0.0)),
            border: isTextBox
                ? (widget.isEditMode
                    ? Border.all(color: Colors.blueAccent.withOpacity(0.4), width: 1.0)
                    : null)
                : (isClip ? Border.all(color: Colors.black12, width: 1) : null),
            boxShadow: isTextBox
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toolbar on Hover / Edit Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.isEditMode) ...[
                    // Font size adjustments
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          item.fontSize = (item.fontSize - 1).clamp(10.0, 36.0);
                        });
                        widget.onChanged();
                      },
                      child: const Icon(Icons.remove, size: 14, color: Colors.black54),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.fontSize.toInt()}',
                      style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          item.fontSize = (item.fontSize + 1).clamp(10.0, 36.0);
                        });
                        widget.onChanged();
                      },
                      child: const Icon(Icons.add, size: 14, color: Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _changeColor(item),
                      child: const Icon(Icons.color_lens, size: 14, color: Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.items.remove(item);
                        });
                        widget.onChanged();
                      },
                      child: const Icon(Icons.close, size: 14, color: Colors.black54),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 4),
              if (item.height != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      item.content,
                      style: TextStyle(
                        fontSize: item.fontSize,
                        color: Colors.black87,
                        fontFamily: isTextBox
                            ? 'sans-serif'
                            : (item.type == 'sticky_note' ? 'cursive' : 'sans-serif'),
                        height: 1.3,
                      ),
                      textAlign: isTextBox
                          ? TextAlign.left
                          : (item.type == 'sticky_note' ? TextAlign.center : TextAlign.start),
                    ),
                  ),
                )
              else
                Text(
                  item.content,
                  style: TextStyle(
                    fontSize: item.fontSize,
                    color: Colors.black87,
                    fontFamily: isTextBox
                        ? 'sans-serif'
                        : (item.type == 'sticky_note' ? 'cursive' : 'sans-serif'),
                    height: 1.3,
                  ),
                  textAlign: isTextBox
                      ? TextAlign.left
                      : (item.type == 'sticky_note' ? TextAlign.center : TextAlign.start),
                ),
            ],
          ),
        ),

        // Realistic metal paper clip hanging off the top
        if (isClip)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 24,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.grey.shade400, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Drag resize handle at bottom-right corner
        if (widget.isEditMode)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanStart: (details) {
                if (item.height == null) {
                  setState(() {
                    item.height = 160.0;
                  });
                }
              },
              onPanUpdate: (details) {
                setState(() {
                  item.width = (item.width + details.delta.dx).clamp(120.0, 800.0);
                  if (item.height != null) {
                    item.height = (item.height! + details.delta.dy).clamp(60.0, 800.0);
                  }
                });
              },
              onPanEnd: (_) {
                widget.onChanged();
              },
              child: const MouseRegion(
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.filter_list,
                    size: 16,
                    color: Colors.black38,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
