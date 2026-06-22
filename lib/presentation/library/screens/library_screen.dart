import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/wood_texture.dart';
import '../widgets/library_header.dart';
import '../widgets/library_sidebar.dart';
import '../widgets/library_shelf_view.dart';
import '../widgets/furniture_frame.dart';
import '../provider/library_provider.dart';
import 'library_book_details.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final activeBookId = ref.watch(activeBookIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Normal light background
      body: Column(
        children: [
          const LibraryHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Content Area (The Bookshelf Furniture)
                  Expanded(
                    child: FurnitureFrame(
                      child: WoodBackground(
                        child: activeBookId != null
                            ? LibraryBookDetails(
                                bookId: activeBookId,
                                onBack: () => ref.read(activeBookIdProvider.notifier).state = null,
                              )
                            : LibraryShelfView(
                                onBookTap: (int bookId) {
                                  ref.read(activeBookIdProvider.notifier).state = bookId;
                                },
                              ),
                      ),
                    ),
                  ),
                  
                  // Fixed Sidebar Area
                  const LibrarySidebar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
