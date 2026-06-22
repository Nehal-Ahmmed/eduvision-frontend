import 'package:url_launcher/url_launcher.dart';

void downloadFileImpl(String url, String fileName) async {
  print('[book download] Mobile/Desktop execution: launching external application for URL: $url');
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    print('[book download] Mobile/Desktop execution error: cannot launch URL: $url');
  }
}

void viewFileImpl(String url) async {
  print('[book download] Mobile/Desktop execution: viewing URL in external application: $url');
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    print('[book download] Mobile/Desktop execution error: cannot launch URL: $url');
  }
}
