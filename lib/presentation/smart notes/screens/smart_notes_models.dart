class NoteNode {
  final int? id;
  final int? parentId;
  final String name;
  final bool isFolder;
  final List<NoteNode> children;
  bool isExpanded;

  NoteNode({
    this.id,
    this.parentId,
    required this.name,
    this.isFolder = false,
    this.children = const [],
    this.isExpanded = false,
  });
}
