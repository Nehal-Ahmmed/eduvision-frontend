import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:academic_project/domain/book.dart';
import '../provider/library_provider.dart';
import 'wooden_shelf.dart';

class LibraryShelfView extends ConsumerStatefulWidget {
  final Function(int bookId) onBookTap;

  const LibraryShelfView({super.key, required this.onBookTap});

  @override
  ConsumerState<LibraryShelfView> createState() => _LibraryShelfViewState();
}

class _LibraryShelfViewState extends ConsumerState<LibraryShelfView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page, int totalPages) {
    if (page >= 0 && page < totalPages) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      loading: () => const SizedBox(
        height: 650,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE29F5C)),
        ),
      ),
      error: (error, stack) => SizedBox(
        height: 650,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFC73024), size: 48),
              const SizedBox(height: 16),
              Text(
                "Failed to load books",
                style: TextStyle(
                  color: const Color(0xFF331801),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.white.withOpacity(0.5), offset: const Offset(0, 1)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => ref.read(booksProvider.notifier).fetchBooks(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE29F5C), Color(0xFF8B5115)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF4A2505), width: 1.5),
                  ),
                  child: const Text("Retry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (books) {
        if (books.isEmpty) {
          return _buildEmptyState();
        }
        return _buildShelvesView(books);
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(0),
        SizedBox(
          height: 650,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books, color: const Color(0xFF331801).withOpacity(0.4), size: 64),
                const SizedBox(height: 16),
                Text(
                  "Your library is empty",
                  style: TextStyle(
                    color: const Color(0xFF331801),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.white.withOpacity(0.5), offset: const Offset(0, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add your first book using the button above",
                  style: TextStyle(
                    color: const Color(0xFF331801).withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShelvesView(List<Book> books) {
    // 12 books per page (3 shelves × 4 books)
    final int booksPerPage = 12;
    final int totalPages = (books.length / booksPerPage).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(books.length),
        
        // Sliding Shelves (PageView)
        SizedBox(
          height: 650, // Fixed height to accommodate 3 shelves vertically without bottom overflow
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: totalPages,
            itemBuilder: (context, index) {
              return _buildPage(books, index, booksPerPage);
            },
          ),
        ),
        
        // Pagination Controls
        const SizedBox(height: 40),
        if (totalPages > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _pageBtn(Icons.skip_previous, () => _goToPage(0, totalPages)),
                _pageBtn(Icons.keyboard_double_arrow_left, () => _goToPage(_currentPage - 1, totalPages)),
                ...List.generate(totalPages, (index) {
                  return _pageText("${index + 1}", _currentPage == index, () => _goToPage(index, totalPages));
                }),
                _pageBtn(Icons.keyboard_double_arrow_right, () => _goToPage(_currentPage + 1, totalPages)),
                _pageBtn(Icons.skip_next, () => _goToPage(totalPages - 1, totalPages)),
              ],
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader(int bookCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Latest Books",
                style: TextStyle(
                  color: Color(0xFF331801),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: Colors.white60, offset: Offset(0, 1), blurRadius: 1),
                    Shadow(color: Colors.black26, offset: Offset(0, -1), blurRadius: 1),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1502),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF5A3108), width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.white24, offset: Offset(0, 1))],
                ),
                child: Text(
                  "Total : $bookCount books",
                  style: const TextStyle(
                    color: Color(0xFFE29F5C),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Elegant divider
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF331801).withOpacity(0.8),
                  const Color(0xFF331801).withOpacity(0.0),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build a full page of up to 3 shelves
  Widget _buildPage(List<Book> allBooks, int pageIndex, int booksPerPage) {
    int startIdx = pageIndex * booksPerPage;
    
    // Split this page's books into rows of 4
    List<List<Book>> shelves = [];
    for (int i = 0; i < 3; i++) {
      int shelfStart = startIdx + (i * 4);
      int shelfEnd = (shelfStart + 4).clamp(0, allBooks.length);
      if (shelfStart < allBooks.length) {
        shelves.add(allBooks.sublist(shelfStart, shelfEnd));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          for (int i = 0; i < shelves.length; i++) ...[
            WoodenShelf(
              width: double.infinity,
              books: shelves[i].map((book) {
                return HoverableBook(
                  title: book.title,
                  hasCover: i % 2 == 0, // Alternate between cover styles for visual variety
                  onTap: () => widget.onBookTap(book.id),
                  author: book.author ?? 'Unknown Author',
                  desc: book.description ?? 'No description available.',
                );
              }).toList(),
            ),
            if (i < shelves.length - 1) const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE29F5C), Color(0xFF8B5115)],
            ),
            border: Border.all(color: const Color(0xFF4A2505), width: 1.5),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              const BoxShadow(color: Colors.black45, offset: Offset(2, 4), blurRadius: 4),
              BoxShadow(color: Colors.white.withOpacity(0.3), offset: const Offset(-1, -1), blurRadius: 1),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _pageText(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: isActive 
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4A2505), Color(0xFF2E1502)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE29F5C), Color(0xFF8B5115)],
                  ),
            border: Border.all(color: const Color(0xFF4A2505), width: 1.5),
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [const BoxShadow(color: Colors.white24, offset: Offset(0, 1))]
                : [
                    const BoxShadow(color: Colors.black45, offset: Offset(2, 3), blurRadius: 3),
                    const BoxShadow(color: Colors.white24, offset: Offset(-1, -1)),
                  ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? const Color(0xFFE29F5C) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              shadows: isActive 
                  ? [const Shadow(color: Colors.black, offset: Offset(1, 1))] 
                  : [const Shadow(color: Colors.black54, offset: Offset(1, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

class HoverableBook extends StatefulWidget {
  final String title;
  final bool hasCover;
  final String author;
  final String desc;
  final VoidCallback onTap;

  const HoverableBook({
    super.key,
    required this.title,
    required this.hasCover,
    required this.author,
    required this.desc,
    required this.onTap,
  });

  @override
  State<HoverableBook> createState() => _HoverableBookState();
}

class _HoverableBookState extends State<HoverableBook> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          _buildBookBody(),
          if (_isHovering) _buildPopover(),
        ],
      ),
    );
  }

  Widget _buildBookBody() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 105,
        height: 150,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: widget.hasCover ? const Color(0xFF3B2A22) : const Color(0xFFE5E5E5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            bottomLeft: Radius.circular(3),
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
          boxShadow: [
            // The heavy contact shadow right beneath the book
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              offset: const Offset(4, 8),
              blurRadius: 10,
            ),
            // The soft ambient shadow cast behind it
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(-2, 10),
              blurRadius: 15,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Photorealistic Book Cover Texture / Grain
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15), // Top-left highlight
                    Colors.transparent,
                    Colors.black.withOpacity(0.2), // Bottom-right shadow
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
            
            // The Physical Spine Hinge (Deep crease)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.7), // Shadow going down into crease
                      Colors.black.withOpacity(0.1), // Base of crease
                      Colors.white.withOpacity(0.4), // Highlight catching the edge of the board
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Hardcover board edge lighting (simulating the physical thickness)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
                    right: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
                    left: BorderSide(color: Colors.black.withOpacity(0.4), width: 1.5),
                    bottom: BorderSide(color: Colors.black.withOpacity(0.7), width: 2.5),
                  ),
                ),
              ),
            ),

            // Actual Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(left: 18.0, right: 8, top: 10, bottom: 10),
                child: widget.hasCover
                    ? Center(
                        child: Text(
                          widget.title.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.2,
                            height: 1.3,
                            shadows: const [
                              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 3),
                              Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 6),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Icon(Icons.menu_book, color: Colors.grey, size: 30),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopover() {
    return Positioned(
      bottom: 165, // Hover directly above the book
      left: -40, // Center it over the book
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8),
          ],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.book, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.edit, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(widget.author, style: const TextStyle(color: Color(0xFFC73024), fontSize: 11))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_align_left, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(widget.desc, style: const TextStyle(fontSize: 10, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.star_border, size: 14, color: Colors.grey),
                    Icon(Icons.star, size: 14, color: Colors.grey),
                    Icon(Icons.star, size: 14, color: Colors.grey),
                    Icon(Icons.star, size: 14, color: Colors.grey),
                    Icon(Icons.star, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
            Positioned(
              top: -16,
              right: -16,
              child: Container(
                width: 20,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFD41919),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
                ),
              ),
            ),
            Positioned(
              bottom: -16,
              right: -16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8CC63F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
