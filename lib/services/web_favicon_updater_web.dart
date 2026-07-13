// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void updateWebFaviconImpl(String faviconUrl) {
  if (faviconUrl.trim().isEmpty) return;
  final existing = html.document.querySelector("link[rel~='icon']");
  final link = existing is html.LinkElement ? existing : html.LinkElement()
    ..rel = 'icon';
  link.href = faviconUrl;
  if (existing == null) {
    html.document.head?.append(link);
  }
}
