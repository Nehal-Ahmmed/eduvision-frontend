# My Library Redesign Guide

## 🗺️ High-Level Roadmap

1. **Replaced Resources Placeholder**: Transitioned the generic "Resources" label to "My Library" in the main navigation.
2. **Skeuomorphic Layout Built**: Developed a fully custom UI using realistic wood textures, simulated physical shelves, and paper-like elements.
3. **Library Shelf View (`LibraryShelfView`)**: Implemented a 4x3 book grid displaying books atop highly stylized 3D wooden shelves, complete with custom pagination controls and hover popovers.
4. **Detailed Notebook View (`LibraryBookDetails`)**: Designed an exact replica of the "King of Lanka" detail screen, utilizing a paper-like white container, red bookmarks, and a mini physical shelf for the selected book.
5. **Sidebar and Search Controls**: Recreated the distinct dropdowns, title inputs, and dark-themed category list specific to "The Readers' Planet".
6. **Wood Texture Generation**: Built `WoodTexturePainter` to procedurally draw realistic wooden grains behind the entire UI, eliminating the need for bulky static image assets.

## 🧠 Logical Descriptions

### Frontend Layer
- **`LibraryScreen`**: The top-level stateful widget. It wraps its children in a `WoodBackground` and conditionally renders either `LibraryShelfView` or `LibraryBookDetails` depending on `_isShowingDetails`.
- **`WoodBackground` & `WoodTexturePainter`**: Employs Flutter's `CustomPainter` to procedurally render random-yet-consistent vertical grain strokes over a solid warm orange-brown base color.
- **`WoodenShelf`**: Combines `Container` borders and drop-shadows to simulate a physical horizontal board jutting out towards the user. It dynamically accepts a row of `books`.
- **`LibraryBookDetails`**: Uses `Stack` to perfectly position floating UI elements like the red ribbon bookmark and the green heart button outside the bounds of the white "paper" card.

### Backend Layer
- *In Development*: Currently, the book data (like "King of Lanka" and "Yogiyuda Athmakadha") is hardcoded in the frontend. Future iterations will map these to `BookEntity` models and fetch via a `LibraryService`.

## 💻 Full Implementation Code

### `library_screen.dart`
```dart
import 'package:flutter/material.dart';
import '../widgets/wood_texture.dart';
import '../widgets/library_header.dart';
import '../widgets/library_sidebar.dart';
import '../widgets/library_shelf_view.dart';
import 'library_book_details.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isShowingDetails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCA86A),
      body: WoodBackground(
        child: Column(
          children: [
            const LibraryHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _isShowingDetails 
                          ? LibraryBookDetails(onBack: () => setState(() => _isShowingDetails = false))
                          : LibraryShelfView(onBookTap: () => setState(() => _isShowingDetails = true)),
                    ),
                    const LibrarySidebar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🛠️ Extra Steps

- To preview the design, simply hot-restart the application.
- Open the sidebar and click on the "My Library" item (which replaced "Resources").

## 📝 Summary

The generic "Resources" section has been entirely transformed into a skeuomorphic "My Library" matching the requested vintage wooden aesthetic. Clicking any book on the massive 4x3 shelves smoothly transitions the view to an isolated detail card sitting on its own mini-shelf, exactly matching the reference images.
