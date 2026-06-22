import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:academic_project/domain/book.dart';
import 'package:academic_project/data/book_remote_data_source.dart';
import 'package:academic_project/utils/download_helper.dart';
import '../provider/library_provider.dart';
import '../widgets/wooden_shelf.dart';
import 'library_pdf_reader_screen.dart';

class LibraryBookDetails extends ConsumerWidget {
  final int bookId;
  final VoidCallback onBack;

  const LibraryBookDetails({
    super.key,
    required this.bookId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE29F5C)),
      ),
      error: (error, stack) => Center(
        child: Text(
          "Error loading book details",
          style: TextStyle(color: const Color(0xFFC73024)),
        ),
      ),
      data: (books) {
        final book = books.where((b) => b.id == bookId).firstOrNull;
        if (book == null) {
          return Center(
            child: Text(
              "Book not found",
              style: TextStyle(color: const Color(0xFFC73024)),
            ),
          );
        }
        return _buildDetails(context, ref, book);
      },
    );
  }

  Widget _buildDetails(BuildContext context, WidgetRef ref, Book book) {
    final dataSource = ref.read(bookDataSourceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFC73024)),
                onPressed: onBack,
              ),
              const Text(
                "Book Details",
                style: TextStyle(
                  color: Color(0xFFC73024),
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 40),
            // Left side: Book on a small shelf
            Column(
              children: [
                Container(
                  width: 140,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E212D),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        offset: Offset(2, 4),
                        blurRadius: 6,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${book.title.toUpperCase()}\n\n${(book.author ?? 'Unknown').toUpperCase()}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                // Small shelf just for the book
                Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4863A),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF8B5115), width: 6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                // Shelf brackets
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 20,
                      color: const Color(0xFF8B5115),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    Container(
                      width: 10,
                      height: 20,
                      color: const Color(0xFF8B5115),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Download button only
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        print('[book download] Download button tapped for book ID: ${book.id}');
                        try {
                          final baseUrl = await dataSource.getBookFileUrl(book.id);
                          final url = '$baseUrl&download=true';
                          print('[book download] Download URL: $url');
                          
                          // Use unified cross-platform download helper
                          downloadFile(url, book.fileName ?? 'book.pdf');
                          print('[book download] Download triggered successfully via downloadFile helper');
                        } catch (e, stack) {
                          print('[book download] Exception in Download tap: $e');
                          print('[book download] Stack trace: $stack');
                        }
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC73024),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF4A2505), width: 1.5),
                            boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(1, 2), blurRadius: 2)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text("Download", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 40),
            // Right side: Paper details
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.save,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              book.title,
                              style: const TextStyle(
                                color: Color(0xFFC73024),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: const Color(0xFFE5E5E5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "ISBN : ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                book.isbn ?? 'N/A',
                                style: const TextStyle(
                                  color: Color(0xFFC73024),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                "No. of pages : ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "${book.numberOfPages ?? 'N/A'}",
                                style: const TextStyle(
                                  color: Color(0xFFC73024),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.menu,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                book.description ?? 'No description provided.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF333333),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.edit,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              book.author ?? 'Unknown Author',
                              style: const TextStyle(
                                color: Color(0xFFC73024),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.language,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              book.language ?? 'Not specified',
                              style: const TextStyle(
                                color: Color(0xFFC73024),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.category,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              book.category ?? 'Uncategorized',
                              style: const TextStyle(
                                color: Color(0xFFC73024),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              book.fileName ?? 'Unknown file',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                              ),
                            ),
                            if (book.fileSize != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                "(${(book.fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB)",
                                style: const TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(
                              Icons.star_border,
                              color: Colors.grey,
                              size: 18,
                            ),
                            Icon(Icons.star, color: Colors.grey, size: 18),
                            Icon(Icons.star, color: Colors.grey, size: 18),
                            Icon(Icons.star, color: Colors.grey, size: 18),
                            Icon(Icons.star, color: Colors.grey, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Red Bookmark
                  Positioned(
                    top: -10,
                    right: 20,
                    child: Container(
                      width: 24,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD41919),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Favorite Heart Button (wired to toggle)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(booksProvider.notifier)
                            .toggleFavorite(book.id);
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: book.isFavorite
                                ? const Color(0xFFC73024)
                                : const Color(0xFF8CC63F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            book.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Delete button
                  Positioned(
                    bottom: 12,
                    right: 56,
                    child: GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Book"),
                            content: Text(
                              "Are you sure you want to delete \"${book.title}\"?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref.read(booksProvider.notifier).deleteBook(book.id);
                          onBack();
                        }
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF666666),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
