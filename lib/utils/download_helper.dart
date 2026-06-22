import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_mobile.dart';

/// Triggers a file download on the client device.
/// Uses native HTML anchors on web to prevent connection abortions/navigating away,
/// and uses standard url_launcher on other platforms.
void downloadFile(String url, String fileName) {
  downloadFileImpl(url, fileName);
}

/// Opens a file in a new tab/window for inline viewing/reading.
/// Uses native HTML window open on web to prevent context navigation,
/// and uses standard url_launcher on other platforms.
void viewFile(String url) {
  viewFileImpl(url);
}
