import 'package:flutter/material.dart';
import '../../theme/app_constants.dart';
import 'smart_notes_left_sidebar.dart';
import 'smart_notes_editor_area.dart';
import 'smart_notes_ai_sidebar.dart';

class SmartNotes extends StatefulWidget {
  const SmartNotes({super.key});

  @override
  State<SmartNotes> createState() => _SmartNotesState();
}

class _SmartNotesState extends State<SmartNotes> {
  int currentTab = 0;
  bool isEditMode = false;
  bool isExplorerVisible = true;
  double aiSidebarWidth = 350.0;
  bool isAiVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartNotesTheme.bgMain,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isExplorerVisible) ...[
            const SizedBox(
              width: SmartNotesTheme.leftSidebarWidth,
              child: SmartNotesLeftSidebar(),
            ),
            Container(width: 1, color: SmartNotesTheme.border),
          ],
          Expanded(
            child: SmartNotesEditorArea(
              currentTab: currentTab,
              isEditMode: isEditMode,
              isAiVisible: isAiVisible,
              onTabChanged: (index) {
                setState(() {
                  currentTab = index;
                });
              },
              onEditModeChanged: (mode) {
                setState(() {
                  isEditMode = mode;
                });
              },
              onAiVisibleChanged: (visible) {
                setState(() {
                  isAiVisible = visible;
                });
              },
              onToggleExplorer: () {
                setState(() {
                  isExplorerVisible = !isExplorerVisible;
                });
              },
            ),
          ),
          if (isAiVisible) ...[
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  aiSidebarWidth = (aiSidebarWidth - details.delta.dx).clamp(280.0, 700.0);
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Container(
                  width: 4,
                  color: SmartNotesTheme.border,
                ),
              ),
            ),
            SizedBox(
              width: aiSidebarWidth,
              child: SmartNotesAiSidebar(
                onClose: () => setState(() => isAiVisible = false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
