import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../provider/library_provider.dart';

class LibraryHeader extends ConsumerStatefulWidget {
  const LibraryHeader({super.key});

  @override
  ConsumerState<LibraryHeader> createState() => _LibraryHeaderState();
}

class _LibraryHeaderState extends ConsumerState<LibraryHeader> {
  void _showAddBookDialog() {
    showDialog(context: context, builder: (context) => const _AddBookDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top wooden strip (transparent so it shows wood background)
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "The Readers' Planet",
                style: TextStyle(
                  fontFamily: 'cursive',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A2A2A),
                  shadows: [
                    Shadow(
                      color: Colors.white54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              // Add Book Button
              GestureDetector(
                onTap: _showAddBookDialog,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Colors.white30, offset: Offset(0, 1)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: const Row(
                      children: [
                        Text(
                          "Add Book",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // White navigation strip
        Container(
          height: 40,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _navLink("Books Store : Drop your books here", true),
                ],
              ),
              // Red ribbon
              Container(
                margin: const EdgeInsets.only(right: 60),
                decoration: const BoxDecoration(
                  color: Color(0xFFD41919),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.library_books, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Personal",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1,
                          ),
                        ),
                        Text(
                          "Library Space",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navLink(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFD41919) : const Color(0xFF555555),
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AddBookDialog extends ConsumerStatefulWidget {
  const _AddBookDialog();

  @override
  ConsumerState<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends ConsumerState<_AddBookDialog> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _author = '';
  String _description = '';
  String _isbn = '';
  String _language = 'English';
  String _category = 'Fiction';
  int _pages = 0;

  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file (PDF/EPUB) first.')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isUploading = true;
    });

    try {
      await ref
          .read(booksProvider.notifier)
          .uploadBook(
            fileBytes: _selectedFile!.bytes!,
            fileName: _selectedFile!.name,
            title: _title,
            author: _author.isEmpty ? null : _author,
            description: _description.isEmpty ? null : _description,
            isbn: _isbn.isEmpty ? null : _isbn,
            language: _language,
            category: _category,
            numberOfPages: _pages > 0 ? _pages : null,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading book: $e')));
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Add New Book",
        style: TextStyle(color: Color(0xFFC73024), fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // File Picker
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.file_upload),
                        label: const Text("Choose File"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE29F5C),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedFile != null
                              ? _selectedFile!.name
                              : 'No file selected (Max 50MB)',
                          style: TextStyle(
                            color: _selectedFile != null
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: _selectedFile != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Title *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? "Title is required"
                      : null,
                  onSaved: (value) => _title = value!.trim(),
                ),
                const SizedBox(height: 16),

                // Author & Category Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Author",
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (value) => _author = value?.trim() ?? '',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                        ),
                        value: _category,
                        items:
                            [
                                  "Fiction",
                                  "Biography",
                                  "Education",
                                  "Science",
                                  "History",
                                  "Astrology",
                                  "Computers",
                                  "Business",
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) =>
                            setState(() => _category = value!),
                        onSaved: (value) => _category = value!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Language & Pages Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Language",
                          border: OutlineInputBorder(),
                        ),
                        value: _language,
                        items:
                            ["English", "Spanish", "French", "German", "Other"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) =>
                            setState(() => _language = value!),
                        onSaved: (value) => _language = value!,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "No. of Pages",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) =>
                            _pages = int.tryParse(value ?? '0') ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ISBN
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "ISBN",
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => _isbn = value?.trim() ?? '',
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  onSaved: (value) => _description = value?.trim() ?? '',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8CC63F),
            foregroundColor: Colors.white,
          ),
          child: _isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Upload Book"),
        ),
      ],
    );
  }
}
