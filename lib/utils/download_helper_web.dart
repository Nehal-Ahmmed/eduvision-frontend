import 'dart:html' as html;

void downloadFileImpl(String url, String fileName) {
  print('[book download] Web execution: initiating anchor download for file: $fileName');
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..target = '_blank'
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  print('[book download] Web execution: anchor click event dispatched');
}

void viewFileImpl(String url) {
  print('[book download] Web execution: opening PDF URL in a new window/tab: $url');
  html.window.open(url, '_blank');
  print('[book download] Web execution: window open dispatched');
}
