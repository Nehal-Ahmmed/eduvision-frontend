# Smart Notes Draw & Whiteboard Guide

## 🗺️ High-Level Roadmap

1. **Integrated Drawing Board**: Added `flutter_drawing_board` to support robust freehand and shape drawing capabilities.
2. **Built the Whiteboard Layout**: Created an infinite canvas-like `Stack` interface for pinning notes and clips.
3. **Implemented Drag & Drop**: Used `GestureDetector` on the whiteboard items to enable dragging, dropping, and double-tap editing.
4. **Integrated with Editor Area**: Added a smooth toggle switch inside the Smart Notes "Draw" tab to flip between the raw Drawing Canvas and the Whiteboard.

## 🧠 Logical Descriptions

### Frontend Layer
- **Simple Description**: The "Draw" tab is now a two-in-one feature. You can either use a digital pen to sketch ideas and draw shapes, or switch to a whiteboard to organize colorful sticky notes and clipped information.
- **Technical Description**: The `SmartNotesEditorArea` manages a boolean state (`_isCanvasMode`) to conditionally render either `SmartNotesDrawingBoard` or `SmartNotesWhiteboard`. 
  - The `SmartNotesDrawingBoard` wraps `flutter_drawing_board`'s `DrawingBoard` widget and controls a custom toolbar for updating paint states (color, stroke width, shape instances).
  - The `SmartNotesWhiteboard` holds a list of `WhiteboardItem` models. The `Stack` maps these items to `Positioned` widgets. `GestureDetector` captures pan updates to modify the `dx/dy` offsets of each item for drag interactions.

### Backend Layer (Not implemented yet)
- **Simple Description**: We are currently saving things only on the screen. If you refresh, it resets.
- **Technical Description**: The current implementation utilizes localized React-like widget state (`setState`) to hold drawing paths and sticky note objects in memory. In future iterations, we will serialize the drawing board export and the `WhiteboardItem` offsets/contents to store them in Firestore/Supabase.

## 💻 Full Implementation Code

### 1. `lib/presentation/smart notes/screens/draw/smart_notes_drawing_board.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import '../../../theme/app_constants.dart';

class SmartNotesDrawingBoard extends StatefulWidget {
  const SmartNotesDrawingBoard({super.key});

  @override
  State<SmartNotesDrawingBoard> createState() => _SmartNotesDrawingBoardState();
}

class _SmartNotesDrawingBoardState extends State<SmartNotesDrawingBoard> {
  final DrawingController _drawingController = DrawingController();

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCustomToolbar(),
        Expanded(
          child: DrawingBoard(
            controller: _drawingController,
            background: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
            ),
            showDefaultActions: true,
            showDefaultTools: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: SmartNotesTheme.bgSecondary,
        border: Border(bottom: BorderSide(color: SmartNotesTheme.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolBtn(
              icon: Icons.draw,
              tooltip: 'Pen',
              isSelected: _drawingController.paintContents.isEmpty || _drawingController.paintContents.last is SimpleLine,
              onTap: () {
                _drawingController.setPaintContent(SimpleLine());
                setState(() {});
              },
            ),
            const SizedBox(width: 8),
            _buildToolBtn(
              icon: Icons.auto_fix_normal,
              tooltip: 'Eraser',
              isSelected: _drawingController.paintContents.isNotEmpty && _drawingController.paintContents.last is Eraser,
              onTap: () {
                _drawingController.setPaintContent(Eraser(color: Colors.white));
                setState(() {});
              },
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 20, color: SmartNotesTheme.border),
            const SizedBox(width: 16),
            _buildToolBtn(
              icon: Icons.crop_square,
              tooltip: 'Rectangle',
              isSelected: false,
              onTap: () {
                _drawingController.setPaintContent(Rectangle());
                setState(() {});
              },
            ),
            const SizedBox(width: 8),
            _buildToolBtn(
              icon: Icons.circle_outlined,
              tooltip: 'Circle',
              isSelected: false,
              onTap: () {
                _drawingController.setPaintContent(Circle());
                setState(() {});
              },
            ),
            const SizedBox(width: 8),
            _buildToolBtn(
              icon: Icons.horizontal_rule,
              tooltip: 'Line',
              isSelected: false,
              onTap: () {
                _drawingController.setPaintContent(StraightLine());
                setState(() {});
              },
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 20, color: SmartNotesTheme.border),
            const SizedBox(width: 16),
            _buildColorBtn(Colors.black),
            _buildColorBtn(Colors.red),
            _buildColorBtn(Colors.blue),
            _buildColorBtn(Colors.green),
            const SizedBox(width: 16),
            Container(width: 1, height: 20, color: SmartNotesTheme.border),
            const SizedBox(width: 16),
            const Text('Size:', style: TextStyle(color: SmartNotesTheme.textMuted, fontSize: 13)),
            Slider(
              value: _drawingController.drawConfig.value.strokeWidth,
              min: 1.0,
              max: 20.0,
              activeColor: SmartNotesTheme.accentBlue,
              onChanged: (val) {
                _drawingController.setStyle(strokeWidth: val);
                setState(() {});
              },
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.undo, color: SmartNotesTheme.iconColor, size: 20),
              onPressed: () => _drawingController.undo(),
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.redo, color: SmartNotesTheme.iconColor, size: 20),
              onPressed: () => _drawingController.redo(),
              tooltip: 'Redo',
            ),
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.redAccent, size: 20),
              onPressed: () => _drawingController.clear(),
              tooltip: 'Clear All',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolBtn({required IconData icon, required String tooltip, required bool isSelected, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? SmartNotesTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: isSelected ? SmartNotesTheme.iconDark : SmartNotesTheme.iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildColorBtn(Color color) {
    bool isSelected = _drawingController.drawConfig.value.color == color;
    return GestureDetector(
      onTap: () {
        _drawingController.setStyle(color: color);
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: SmartNotesTheme.accentBlue, width: 2) : Border.all(color: Colors.transparent),
          boxShadow: [
            if (isSelected) BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)
          ],
        ),
      ),
    );
  }
}
```

### 2. `lib/presentation/smart notes/screens/draw/smart_notes_whiteboard.dart`
```dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/app_constants.dart';

class WhiteboardItem {
  final String id;
  Offset position;
  final String type; // 'sticky_note' or 'clip'
  String content;
  Color color;

  WhiteboardItem({
    required this.id,
    required this.position,
    required this.type,
    this.content = '',
    this.color = Colors.amber,
  });
}

class SmartNotesWhiteboard extends StatefulWidget {
  const SmartNotesWhiteboard({super.key});

  @override
  State<SmartNotesWhiteboard> createState() => _SmartNotesWhiteboardState();
}

class _SmartNotesWhiteboardState extends State<SmartNotesWhiteboard> {
  final List<WhiteboardItem> _items = [];
  final _uuid = const Uuid();

  void _addStickyNote() {
    setState(() {
      _items.add(WhiteboardItem(
        id: _uuid.v4(),
        position: const Offset(100, 100),
        type: 'sticky_note',
        content: 'New Sticky Note\nDouble tap to edit',
        color: AppColors.yellow200,
      ));
    });
  }

  void _addNoteClip() {
    setState(() {
      _items.add(WhiteboardItem(
        id: _uuid.v4(),
        position: const Offset(150, 150),
        type: 'clip',
        content: 'Sample Note Clip:\n"Photosynthesis is the process..."',
        color: AppColors.blue100,
      ));
    });
  }

  void _editStickyNote(WhiteboardItem item) {
    TextEditingController controller = TextEditingController(text: item.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sticky Note'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item.content = controller.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _bringToFront(WhiteboardItem item) {
    setState(() {
      _items.remove(item);
      _items.add(item);
    });
  }

  void _changeColor(WhiteboardItem item) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change Background Color'),
        children: [
          _colorOption(item, AppColors.yellow200, 'Yellow', ctx),
          _colorOption(item, AppColors.green200, 'Green', ctx),
          _colorOption(item, AppColors.blue200, 'Blue', ctx),
          _colorOption(item, AppColors.pink50, 'Pink', ctx),
          _colorOption(item, AppColors.purple200, 'Purple', ctx),
        ],
      ),
    );
  }

  SimpleDialogOption _colorOption(WhiteboardItem item, Color color, String name, BuildContext ctx) {
    return SimpleDialogOption(
      onPressed: () {
        setState(() => item.color = color);
        Navigator.pop(ctx);
      },
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black12))),
          const SizedBox(width: 12),
          Text(name),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Container(
            color: SmartNotesTheme.bgSecondary,
            child: Stack(
              children: [
                ..._items.map((item) => Positioned(
                      left: item.position.dx,
                      top: item.position.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            item.position += details.delta;
                          });
                        },
                        onPanStart: (_) => _bringToFront(item),
                        onDoubleTap: () {
                          if (item.type == 'sticky_note') _editStickyNote(item);
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: SmartNotesTheme.bgMain,
        border: Border(bottom: BorderSide(color: SmartNotesTheme.border)),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _addStickyNote,
            icon: const Icon(Icons.sticky_note_2, size: 18),
            label: const Text('Add Sticky Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow400,
              foregroundColor: Colors.black87,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _addNoteClip,
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('Clip Note Portion'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SmartNotesTheme.textMain,
            ),
          ),
          const Spacer(),
          const Text('Drag to move • Double-tap to edit', style: SmartNotesTheme.caption),
        ],
      ),
    );
  }

  Widget _buildItem(WhiteboardItem item) {
    if (item.type == 'sticky_note') {
      return Container(
        width: 200,
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.color,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(2, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _changeColor(item),
                  child: const Icon(Icons.color_lens, size: 16, color: Colors.black54),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _items.remove(item)),
                  child: const Icon(Icons.close, size: 16, color: Colors.black54),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  item.content,
                  style: const TextStyle(fontSize: 16, color: Colors.black87, fontFamily: 'Kalam'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Clip
      return Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.blue200, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.push_pin, size: 16, color: AppColors.blue500),
                const SizedBox(width: 8),
                const Text('Clipped Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.blue500)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _items.remove(item)),
                  child: const Icon(Icons.close, size: 16, color: Colors.black54),
                ),
              ],
            ),
            const Divider(),
            Text(
              item.content,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      );
    }
  }
}
```

## 🛠️ Extra Steps
1. Make sure to run `flutter pub get` as `flutter_drawing_board` and `uuid` are required.
2. Run `flutter run -d chrome`.

## 📝 Summary
1. The user clicks the **Draw** tab in the Smart Notes screen.
2. By default, they are presented with a blank drawing canvas and a custom toolbar to select pens, erasers, and shapes.
3. They can toggle the switch in the top right to swap to **Whiteboard** mode.
4. In Whiteboard mode, they can spawn Sticky Notes and Note Clips, drag them around, change sticky note colors, and double tap to edit content.
