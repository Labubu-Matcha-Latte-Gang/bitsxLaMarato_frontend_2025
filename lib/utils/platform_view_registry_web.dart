import 'dart:ui' as ui;

void registerPlatformViewFactoryImpl(
  String viewType,
  dynamic Function(int viewId) factory,
) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewType, factory);
}
