import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/note.dart';
import '../../theme/app_constants.dart';
import '../provider/notes_provider.dart';
import 'smart_notes_models.dart';

class SmartNotesLeftSidebar extends ConsumerStatefulWidget {
  const SmartNotesLeftSidebar({super.key});

  @override
  ConsumerState<SmartNotesLeftSidebar> createState() => _SmartNotesLeftSidebarState();
}

class _SmartNotesLeftSidebarState extends ConsumerState<SmartNotesLeftSidebar> {
  final Set<int> expandedFolderIds = {};
  int? selectedFolderId;
  String searchString = '';

  List<NoteNode> buildTree(List<Note> notes, {int? parentId}) {
    final List<NoteNode> tree = [];
    final levelNotes = notes.where((note) => note.parentId == parentId).toList();

    for (var note in levelNotes) {
      if (note.isFolder) {
        final children = buildTree(notes, parentId: note.id);
        tree.add(
          NoteNode(
            id: note.id,
            parentId: note.parentId,
            name: note.topic,
            isFolder: true,
            children: children,
            isExpanded: expandedFolderIds.contains(note.id),
          ),
        );
      } else {
        tree.add(
          NoteNode(
            id: note.id,
            parentId: note.parentId,
            name: note.topic.endsWith('.note') || note.topic.endsWith('.txt')
                ? note.topic
                : '${note.topic}.note',
            isFolder: false,
          ),
        );
      }
    }
    return tree;
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SmartNotesTheme.bgSecondary,
        title: const Text('Create Folder', style: TextStyle(color: SmartNotesTheme.textMain)),
        content: TextField(
          controller: controller,
          style: SmartNotesTheme.body,
          decoration: const InputDecoration(
            hintText: 'Folder Name',
            hintStyle: TextStyle(color: SmartNotesTheme.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: SmartNotesTheme.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: SmartNotesTheme.accentBlue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: SmartNotesTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SmartNotesTheme.accentBlue),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(notesProvider.notifier).createFolder(
                  controller.text,
                  parentId: selectedFolderId,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateNoteDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SmartNotesTheme.bgSecondary,
        title: const Text('Create Note', style: TextStyle(color: SmartNotesTheme.textMain)),
        content: TextField(
          controller: controller,
          style: SmartNotesTheme.body,
          decoration: const InputDecoration(
            hintText: 'Note Title',
            hintStyle: TextStyle(color: SmartNotesTheme.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: SmartNotesTheme.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: SmartNotesTheme.accentBlue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: SmartNotesTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SmartNotesTheme.accentBlue),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(notesProvider.notifier).addNote(
                  '',
                  'Notes',
                  controller.text,
                  parentId: selectedFolderId,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Note> _filterNotesWithHierarchy(List<Note> notes, String query) {
    if (query.isEmpty) return notes;
    final lowerQuery = query.toLowerCase();
    final Set<int> idsToKeep = {};
    for (final note in notes) {
      if (note.topic.toLowerCase().contains(lowerQuery)) {
        idsToKeep.add(note.id);
        _addAllParents(notes, note.parentId, idsToKeep);
      }
    }
    return notes.where((n) => idsToKeep.contains(n.id)).toList();
  }

  void _addAllParents(List<Note> notes, int? parentId, Set<int> ids) {
    if (parentId == null) return;
    ids.add(parentId);
    final parent = notes.where((n) => n.id == parentId).firstOrNull;
    if (parent != null) {
      _addAllParents(notes, parent.parentId, ids);
    }
  }

  void _showDeleteConfirmDialog(int id, String name, {required bool isFolder}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SmartNotesTheme.bgSecondary,
        title: Text(
          isFolder ? 'Delete Folder' : 'Delete Note',
          style: const TextStyle(color: SmartNotesTheme.textMain, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isFolder
              ? 'Are you sure you want to delete the folder "$name" and all of its contents? This cannot be undone.'
              : 'Are you sure you want to delete the note "$name"? This cannot be undone.',
          style: SmartNotesTheme.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: SmartNotesTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(notesProvider.notifier).deleteNote(id);
              if (!isFolder && ref.read(activeNoteIdProvider) == id) {
                ref.read(activeNoteIdProvider.notifier).state = null;
              }
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);

    return Container(
      color: SmartNotesTheme.bgMain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Smart\nNotes', style: SmartNotesTheme.heading1),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.note_add_outlined, color: SmartNotesTheme.iconColor, size: 18),
                      onPressed: _showCreateNoteDialog,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.create_new_folder_outlined, color: SmartNotesTheme.iconColor, size: 18),
                      onPressed: _showCreateFolderDialog,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                )
              ],
            ),
          ),

          // Selected folder indicator
          notesState.when(
            data: (notes) {
              if (selectedFolderId == null) return const SizedBox.shrink();
              final selectedFolder = notes.firstWhere(
                (n) => n.id == selectedFolderId,
                orElse: () => Note(
                  id: -1,
                  content: '',
                  subject: '',
                  topic: 'Root',
                  bookmarked: false,
                  isFolder: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              if (selectedFolder.id == -1) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SmartNotesTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(SmartNotesTheme.radiusSmall),
                    border: Border.all(color: SmartNotesTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_open, size: 14, color: SmartNotesTheme.accentBlue),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Folder: ${selectedFolder.topic}',
                          style: const TextStyle(fontSize: 11, color: SmartNotesTheme.accentBlue, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() => selectedFolderId = null),
                        child: const Icon(Icons.close, size: 14, color: SmartNotesTheme.textMuted),
                      )
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Search & Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(color: SmartNotesTheme.bgSecondary, borderRadius: BorderRadius.circular(SmartNotesTheme.radiusMedium), border: Border.all(color: SmartNotesTheme.border)),
              child: TextField(
                style: SmartNotesTheme.body,
                onChanged: (val) {
                  setState(() {
                    searchString = val;
                  });
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: SmartNotesTheme.iconColor, size: 18),
                  border: InputBorder.none,
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: SmartNotesTheme.textMuted, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: SmartNotesTheme.bgSecondary, borderRadius: BorderRadius.circular(SmartNotesTheme.radiusSmall)),
                  child: const Row(children: [Text('Advanced', style: SmartNotesTheme.bodySmall), SizedBox(width: 4), Icon(Icons.tune, color: SmartNotesTheme.iconColor, size: 16)]),
                ),
                const Icon(Icons.filter_list, color: SmartNotesTheme.iconColor, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: SmartNotesTheme.border, height: 1),
          
          // Explorer Tree Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: SmartNotesTheme.bgSecondary,
            child: const Text('EXPLORER', style: TextStyle(color: SmartNotesTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          
          // File Tree
          Expanded(
            child: notesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red, fontSize: 12))),
              data: (notes) {
                final tree = buildTree(_filterNotesWithHierarchy(notes, searchString));
                if (tree.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No notes or folders.\nClick icons above to create.',
                        style: TextStyle(color: SmartNotesTheme.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: tree.length,
                  itemBuilder: (context, index) {
                    return _buildTreeNode(tree[index], 0);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTreeNode(NoteNode node, int depth) {
    if (node.isFolder) {
      bool isSelectedFolder = selectedFolderId == node.id;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (node.id != null) {
                  if (expandedFolderIds.contains(node.id)) {
                    expandedFolderIds.remove(node.id);
                  } else {
                    expandedFolderIds.add(node.id!);
                  }
                  // Single tap selects the folder
                  selectedFolderId = isSelectedFolder ? null : node.id;
                }
              });
            },
            child: Container(
              color: isSelectedFolder ? SmartNotesTheme.accentBlue.withOpacity(0.08) : Colors.transparent,
              child: Padding(
                padding: EdgeInsets.only(left: 16.0 + (depth * 12.0), right: 16.0, top: 6, bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                      color: SmartNotesTheme.iconColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.folder, color: SmartNotesTheme.accentBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        node.name,
                        style: TextStyle(
                          color: isSelectedFolder ? SmartNotesTheme.accentBlue : SmartNotesTheme.textMain,
                          fontSize: 13,
                          fontWeight: isSelectedFolder ? FontWeight.bold : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelectedFolder) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirmDialog(node.id!, node.name, isFolder: true),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete Folder',
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
          if (node.isExpanded)
            ...node.children.map((child) => _buildTreeNode(child, depth + 1)),
        ],
      );
    }

    // If it's a file
    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = SmartNotesTheme.iconColor;
    if (node.name.endsWith('.note')) {
      fileIcon = Icons.description;
      iconColor = const Color(0xFFE2B93B);
    } else if (node.name.endsWith('.txt')) {
      fileIcon = Icons.subject;
      iconColor = const Color(0xFF519ABA);
    }

    final activeNoteId = ref.watch(activeNoteIdProvider);
    bool isSelectedFile = activeNoteId == node.id;

    return InkWell(
      onTap: () {
        ref.read(activeNoteIdProvider.notifier).state = node.id;
      },
      child: Container(
        color: isSelectedFile ? SmartNotesTheme.accentBlue.withOpacity(0.12) : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(left: 16.0 + (depth * 12.0) + 20.0, right: 16.0, top: 4, bottom: 4),
          child: Row(
            children: [
              Icon(fileIcon, color: isSelectedFile ? SmartNotesTheme.accentBlue : iconColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  style: TextStyle(
                    color: isSelectedFile ? SmartNotesTheme.textMain : SmartNotesTheme.textMuted,
                    fontSize: 13,
                    fontWeight: isSelectedFile ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelectedFile) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmDialog(node.id!, node.name, isFolder: false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete Note',
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
