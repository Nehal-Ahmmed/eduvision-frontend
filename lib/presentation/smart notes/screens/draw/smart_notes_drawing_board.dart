import 'package:flutter/material.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';
import 'smart_notes_custom_painter.dart';

class SmartNotesDrawingBoard extends StatefulWidget {
  final DrawingController controller;
  final bool isEditMode;

  const SmartNotesDrawingBoard({
    super.key,
    required this.controller,
    required this.isEditMode,
  });

  @override
  State<SmartNotesDrawingBoard> createState() => _SmartNotesDrawingBoardState();
}

class _SmartNotesDrawingBoardState extends State<SmartNotesDrawingBoard> {
  final GlobalKey _canvasKey = GlobalKey();
  bool _isLeftPanelExpanded = true;
  bool _isRightPanelExpanded = true;

  final List<Map<String, dynamic>> _graphsAndShapes = [
    // Graphs
    {'name': 'axes', 'label': 'Axes Grid', 'icon': Icons.grid_4x4, 'category': 'Graphs'},
    {'name': 'sine', 'label': 'Sine Wave', 'icon': Icons.waves, 'category': 'Graphs'},
    {'name': 'cosine', 'label': 'Cosine Wave', 'icon': Icons.gesture, 'category': 'Graphs'},
    {'name': 'parabola', 'label': 'Parabola', 'icon': Icons.show_chart, 'category': 'Graphs'},
    {'name': 'bell', 'label': 'Normal Curve', 'icon': Icons.trending_up, 'category': 'Graphs'},
    {'name': 'exponential', 'label': 'Exponential', 'icon': Icons.timeline, 'category': 'Graphs'},
    // Shapes
    {'name': 'cube', 'label': '3D Cube', 'icon': Icons.view_in_ar, 'category': 'Shapes'},
    {'name': 'cylinder', 'label': 'Cylinder', 'icon': Icons.filter_hdr, 'category': 'Shapes'},
    {'name': 'sphere', 'label': 'Sphere', 'icon': Icons.blur_on, 'category': 'Shapes'},
    {'name': 'human', 'label': 'Human Stick', 'icon': Icons.accessibility_new, 'category': 'Shapes'},
    // CSE Icons
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

  void _showTextBoxDialog(BuildContext context, Offset position, {DrawingStroke? existingStroke}) {
    final textController = TextEditingController(
      text: existingStroke != null ? existingStroke.tool.substring(5) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SmartNotesTheme.bgSecondary,
        title: Text(
          existingStroke != null ? 'Edit Text Box' : 'Add Text Box',
          style: const TextStyle(color: SmartNotesTheme.textMain, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          maxLines: 3,
          autofocus: true,
          style: SmartNotesTheme.body,
          decoration: const InputDecoration(
            hintText: 'Type text to add manually...',
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
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                if (existingStroke != null) {
                  widget.controller.editTextStroke(existingStroke, text);
                } else {
                  widget.controller.addTextStroke(position, text);
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isEditMode) _buildCustomToolbar(),
        Expanded(
          child: GestureDetector(
            key: _canvasKey,
            onPanStart: widget.isEditMode
                ? (details) {
                    final RenderBox? box =
                        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localPos = box.globalToLocal(details.globalPosition);
                      if (widget.controller.currentTool == 'Text Box') {
                        _showTextBoxDialog(context, localPos);
                      } else {
                        widget.controller.startStroke(localPos);
                      }
                    }
                  }
                : null,
            onPanUpdate: widget.isEditMode
                ? (details) {
                    final RenderBox? box =
                        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localPos = box.globalToLocal(details.globalPosition);
                      if (widget.controller.currentTool == 'Move') {
                        widget.controller.dragSelected(details.delta);
                      } else {
                        widget.controller.updateStroke(localPos);
                      }
                    }
                  }
                : null,
            onPanEnd: widget.isEditMode
                ? (_) {
                    widget.controller.endStroke();
                  }
                : null,
            onDoubleTapDown: widget.isEditMode
                ? (details) {
                    final RenderBox? box =
                        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localPos = box.globalToLocal(details.globalPosition);
                      for (var s in widget.controller.strokes) {
                        if (s.tool.startsWith('text:')) {
                          final rect = Rect.fromPoints(
                            s.points.first.toOffset(),
                            s.points.last.toOffset(),
                          );
                          if (rect.contains(localPos)) {
                            _showTextBoxDialog(context, s.points.first.toOffset(), existingStroke: s);
                            break;
                          }
                        }
                      }
                    }
                  }
                : null,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
              child: ClipRect(
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: CustomDrawingPainter(
                        widget.controller.strokes,
                        selectedStroke: widget.controller.selectedStroke,
                        imageCache: widget.controller.imageCache,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarToggle({
    required bool isLeft,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 14,
        height: 60,
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
        child: Center(
          child: Icon(
            isLeft
                ? (isExpanded ? Icons.chevron_left : Icons.chevron_right)
                : (isExpanded ? Icons.chevron_right : Icons.chevron_left),
            size: 11,
            color: SmartNotesTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSidebar() {
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
              _buildPrefabGrid('Graphs'),
              const SizedBox(height: 16),
              _buildSectionTitle('Geometric Shapes'),
              _buildPrefabGrid('Shapes'),
              const SizedBox(height: 16),
              _buildSectionTitle('CSE Diagrams & Nodes'),
              _buildPrefabGrid('CSE Icons'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightSidebar() {
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
            'Templates & Tables',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SmartNotesTheme.textMain),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              _buildSectionTitle('Database Tables'),
              _buildPrefabList('DB Tables'),
              const SizedBox(height: 16),
              _buildSectionTitle('UML Diagrams'),
              _buildPrefabList('UML / Programming'),
              const SizedBox(height: 16),
              _buildSectionTitle('Flowchart Elements'),
              _buildPrefabGrid('Flowchart', isRightSide: true),
            ],
          ),
        ),
      ],
    );
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

  Widget _buildPrefabGrid(String category, {bool isRightSide = false}) {
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
        return _buildDraggablePrefabItem(item['name'], item['icon'], item['label']);
      },
    );
  }

  Widget _buildPrefabList(String category) {
    final list = _tablesAndFlow.where((e) => e['category'] == category).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = list[i];
        return Draggable<String>(
          data: item['name'],
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                border: Border.all(color: SmartNotesTheme.accentBlue, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item['label'],
                style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: GestureDetector(
            onTap: () => widget.controller.addPrefabStroke(item['name']),
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
          ),
        );
      },
    );
  }

  Widget _buildDraggablePrefabItem(String name, IconData icon, String label) {
    return Draggable<String>(
      data: name,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: SmartNotesTheme.accentBlue, width: 1.5),
          ),
          child: Icon(icon, color: SmartNotesTheme.accentBlue, size: 20),
        ),
      ),
      child: GestureDetector(
        onTap: () => widget.controller.addPrefabStroke(name),
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
      ),
    );
  }

  Widget _buildCustomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: SmartNotesTheme.bgSecondary,
        border: Border(bottom: BorderSide(color: SmartNotesTheme.border)),
      ),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolBtn(
                  icon: Icons.draw,
                  tooltip: 'Pen',
                  isSelected: widget.controller.currentTool == 'Pen',
                  onTap: () {
                    setState(() => widget.controller.currentTool = 'Pen');
                  },
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.auto_fix_normal,
                  tooltip: 'Eraser',
                  isSelected: widget.controller.currentTool == 'Eraser',
                  onTap: () {
                    setState(() => widget.controller.currentTool = 'Eraser');
                  },
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.open_with,
                  tooltip: 'Move / Resize Prefabs',
                  isSelected: widget.controller.currentTool == 'Move',
                  onTap: () {
                    setState(() => widget.controller.currentTool = 'Move');
                  },
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.title,
                  tooltip: 'Text Box',
                  isSelected: widget.controller.currentTool == 'Text Box',
                  onTap: () {
                    setState(() => widget.controller.currentTool = 'Text Box');
                  },
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: SmartNotesTheme.border),
                const SizedBox(width: 16),
                _buildToolBtn(
                  icon: Icons.crop_square,
                  tooltip: 'Rectangle',
                  isSelected: widget.controller.currentTool == 'Rectangle',
                  onTap: () {
                    setState(() => widget.controller.currentTool = 'Rectangle');
                  },
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.circle_outlined,
                  tooltip: 'Circle',
                  isSelected: widget.controller.currentTool == 'Circle',
                  onTap: () {
                    setState(() => widget.controller.currentTool = 'Circle');
                  },
                ),
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.horizontal_rule,
                  tooltip: 'Line',
                  isSelected: widget.controller.currentTool == 'Line',
                  onTap: () {
                    setState(() => widget.controller.currentTool = 'Line');
                  },
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: SmartNotesTheme.border),
                const SizedBox(width: 16),
                _buildColorBtn(Colors.black),
                _buildColorBtn(Colors.red),
                _buildColorBtn(Colors.blue),
                _buildColorBtn(Colors.green),
                _buildColorBtn(Colors.orange),
                _buildColorBtn(Colors.purple),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: SmartNotesTheme.border),
                const SizedBox(width: 16),
                const Text(
                  'Size:',
                  style: TextStyle(color: SmartNotesTheme.textMuted, fontSize: 13),
                ),
                Slider(
                  value: widget.controller.currentWidth,
                  min: 1.0,
                  max: 20.0,
                  activeColor: SmartNotesTheme.accentBlue,
                  onChanged: (val) {
                    setState(() {
                      widget.controller.currentWidth = val;
                    });
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.undo, color: SmartNotesTheme.iconColor, size: 20),
                  onPressed: () => widget.controller.undo(),
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.redo, color: SmartNotesTheme.iconColor, size: 20),
                  onPressed: () => widget.controller.redo(),
                  tooltip: 'Redo',
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.redAccent, size: 20),
                  onPressed: () => widget.controller.clear(),
                  tooltip: 'Clear All',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolBtn({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? SmartNotesTheme.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : SmartNotesTheme.iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildColorBtn(Color color) {
    bool isSelected = widget.controller.currentColor == color &&
        widget.controller.currentTool != 'Eraser';
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.controller.currentColor = color;
          if (widget.controller.currentTool == 'Eraser') {
            widget.controller.currentTool = 'Pen';
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: SmartNotesTheme.accentBlue, width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              )
          ],
        ),
      ),
    );
  }
}
