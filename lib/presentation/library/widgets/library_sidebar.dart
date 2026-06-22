import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/library_provider.dart';
import '../widgets/wood_texture.dart';

class LibrarySidebar extends ConsumerStatefulWidget {
  const LibrarySidebar({super.key});

  @override
  ConsumerState<LibrarySidebar> createState() => _LibrarySidebarState();
}

class _LibrarySidebarState extends ConsumerState<LibrarySidebar> {
  final TextEditingController _searchController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedAuthor;
  String? _selectedLanguage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    ref.read(booksProvider.notifier).searchBooks(
      query: _searchController.text,
      category: _selectedCategory,
      author: _selectedAuthor,
      language: _selectedLanguage,
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedAuthor = null;
      _selectedLanguage = null;
    });
    ref.read(booksProvider.notifier).fetchBooks(); // Reset to all
  }

  @override
  Widget build(BuildContext context) {
    // Watch filter distinct values
    final categoriesAsync = ref.watch(bookCategoriesProvider);
    final authorsAsync = ref.watch(bookAuthorsProvider);
    final languagesAsync = ref.watch(bookLanguagesProvider);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(top: 24, right: 40, bottom: 24),
      decoration: BoxDecoration(
        border: const Border(
          top: BorderSide(color: Color(0xFFFDE0B4), width: 3),
          left: BorderSide(color: Color(0xFFE29F5C), width: 3),
          right: BorderSide(color: Color(0xFF8B5115), width: 3),
          bottom: BorderSide(color: Color(0xFF4A2505), width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(10, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: WoodBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Search",
                    style: TextStyle(
                      color: Color(0xFF331801),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.white54, offset: Offset(0, 1), blurRadius: 1),
                        Shadow(color: Colors.black26, offset: Offset(0, -1), blurRadius: 1),
                      ],
                    ),
                  ),
                  if (_searchController.text.isNotEmpty || _selectedCategory != null || _selectedAuthor != null || _selectedLanguage != null)
                    GestureDetector(
                      onTap: _clearFilters,
                      child: const Text("Clear", style: TextStyle(color: Color(0xFFC73024), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Category Dropdown
              _buildFilterDropdown(
                hint: "Select Category",
                value: _selectedCategory,
                items: categoriesAsync.valueOrNull ?? [],
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                    if (val != null) {
                      _searchController.clear();
                      _selectedAuthor = null;
                      _selectedLanguage = null;
                    }
                  });
                  _performSearch();
                },
              ),
              const SizedBox(height: 12),
              
              // Author Dropdown
              _buildFilterDropdown(
                hint: "Select Author",
                value: _selectedAuthor,
                items: authorsAsync.valueOrNull ?? [],
                onChanged: (val) {
                  setState(() => _selectedAuthor = val);
                  _performSearch();
                },
              ),
              const SizedBox(height: 12),
              
              // Language Dropdown
              _buildFilterDropdown(
                hint: "Select Language",
                value: _selectedLanguage,
                items: languagesAsync.valueOrNull ?? [],
                onChanged: (val) {
                  setState(() => _selectedLanguage = val);
                  _performSearch();
                },
              ),
              const SizedBox(height: 12),

              // Title input (Recessed)
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB06E35), Color(0xFFC58140)],
                  ),
                  border: Border(
                    top: BorderSide(color: Color(0xFF5A3108), width: 3),
                    left: BorderSide(color: Color(0xFF7A4211), width: 2),
                    right: BorderSide(color: Color(0xFFE29F5C), width: 1),
                    bottom: BorderSide(color: Color(0xFFFDE0B4), width: 2),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Title / Keyword",
                    hintStyle: TextStyle(color: Color(0xFF5A3108), fontSize: 13, fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                  onChanged: (_) => _performSearch(),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _performSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE29F5C), Color(0xFF8B5115)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF4A2505), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, offset: Offset(2, 4), blurRadius: 4),
                          BoxShadow(color: Colors.white30, offset: Offset(-1, -1), blurRadius: 1),
                        ],
                      ),
                      child: const Text(
                        "SEARCH", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 13, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          shadows: [Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Quick Categories",
                style: TextStyle(
                  color: Color(0xFF331801),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: Colors.white54, offset: Offset(0, 1), blurRadius: 1),
                    Shadow(color: Colors.black26, offset: Offset(0, -1), blurRadius: 1),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Map over actual distinct categories from user's library, or fallback to defaults
              ...(categoriesAsync.valueOrNull?.isNotEmpty == true 
                  ? categoriesAsync.valueOrNull!.take(8).map((c) => _categoryItem(c))
                  : [
                      _categoryItem("Fiction"),
                      _categoryItem("Biography"),
                      _categoryItem("Education"),
                      _categoryItem("Science"),
                      _categoryItem("History"),
                    ]
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB06E35), Color(0xFFC58140)],
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF5A3108), width: 3),
          left: BorderSide(color: Color(0xFF7A4211), width: 2),
          right: BorderSide(color: Color(0xFFE29F5C), width: 1),
          bottom: BorderSide(color: Color(0xFFFDE0B4), width: 2),
        ),
      ),
      padding: const EdgeInsets.only(left: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(color: Color(0xFF5A3108), fontSize: 13, fontWeight: FontWeight.bold)),
          icon: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF4A2505),
              border: Border(left: BorderSide(color: Color(0xFF2E1502), width: 2)),
            ),
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
          ),
          dropdownColor: const Color(0xFFB06E35),
          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _categoryItem(String name) {
    final bool isSelected = _selectedCategory == name;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategory = null;
              } else {
                _selectedCategory = name;
                _searchController.clear();
                _selectedAuthor = null;
                _selectedLanguage = null;
              }
            });
            _performSearch();
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected 
                      ? [const Color(0xFFC73024), const Color(0xFF8B0000)]
                      : [const Color(0xFFE29F5C), const Color(0xFF8B5115)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4A2505), width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, offset: Offset(1, 2), blurRadius: 2),
                  ]
                ),
                child: const Icon(Icons.play_arrow, size: 10, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFC73024) : const Color(0xFF331801),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: const [
                      Shadow(color: Colors.white54, offset: Offset(0, 1), blurRadius: 1),
                    ]
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
