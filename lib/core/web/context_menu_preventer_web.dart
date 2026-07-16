import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'context_menu_preventer_types.dart';

ContextMenuPreventerDisposer installContextMenuPreventer(
  ContextMenuShouldPrevent shouldPrevent,
) {
  void handleContextMenu(web.Event event) {
    final mouseEvent = event as web.MouseEvent;
    if (!shouldPrevent(
      mouseEvent.clientX.toDouble(),
      mouseEvent.clientY.toDouble(),
    )) {
      return;
    }
    event.preventDefault();
  }

  final listener = handleContextMenu.toJS;
  web.document.addEventListener('contextmenu', listener);
  return () => web.document.removeEventListener('contextmenu', listener);
}
