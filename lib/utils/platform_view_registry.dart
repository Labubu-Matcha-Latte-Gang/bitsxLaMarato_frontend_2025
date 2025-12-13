import 'platform_view_registry_stub.dart'
    if (dart.library.html) 'platform_view_registry_web.dart';

void registerPlatformViewFactory(
  String viewType,
  dynamic Function(int viewId) factory,
) {
  registerPlatformViewFactoryImpl(viewType, factory);
}
