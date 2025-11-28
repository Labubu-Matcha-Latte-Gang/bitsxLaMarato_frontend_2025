# bitsxLaMarato_frontend_2025

Aplicación Flutter del frontend para BitsXMarató 2025.

## Stack generado
- Flutter 3.24.0 (Dart 3.5)
- Targets listos: Android, iOS, Web, Windows, Linux y macOS
- Tests iniciales en `test/widget_test.dart`

## Requisitos previos
1. **Flutter SDK** disponible en el PATH (`flutter --version`). En Windows puedes descargar el ZIP desde [docs.flutter.dev](https://docs.flutter.dev/get-started/install/windows) y descomprimirlo en `C:\tools\flutter`.
2. **Java 11-19** recomendado para Gradle 7.6.3 (actualmente se detectó JDK 21 en la máquina). Considera Temurin 17 y configura `flutter config --jdk-dir <ruta>`.
3. **Android Studio** (para Android SDK/AVD) o un dispositivo físico. Ejecuta `flutter doctor` y resuelve lo necesario.
4. Plugins Flutter/Dart en IntelliJ IDEA Ultimate 2025.2 (ya detectado por `flutter doctor`).

## Puesta en marcha rápida
```powershell
# 1) Clona el repo y entra en la carpeta
cd C:\Users\ernes\Documents\GitHub\bitsxLaMarato_frontend_2025

# 2) Asegura que Flutter está en el PATH de esta sesión
$env:Path += ';C:\Users\ernes\flutter\flutter\bin'

# 3) Diagnóstico del entorno
flutter doctor

# 4) Dependencias y tests
flutter pub get
flutter test

# 5) Ejecutar la app (elige dispositivo con flutter devices)
flutter run -d chrome
```

## Estructura relevante
| Ruta | Descripción |
| --- | --- |
| `lib/main.dart` | Punto de entrada Flutter. |
| `pubspec.yaml` | Dependencias y config del proyecto. |
| `analysis_options.yaml` | Reglas de lint. |
| `test/widget_test.dart` | Smoke test generado por defecto. |
| `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` | Targets nativos. |

## Flujo de trabajo
- Tras cambios en `pubspec.yaml`: `flutter pub get`.
- Lint/format: `flutter analyze` y `flutter format .`.
- Ejecutar pruebas: `flutter test`.
- En IntelliJ: abre el proyecto, usa la configuración `main.dart` para Run/Debug.

## Notas
- Puedes desactivar analíticas: `flutter config --disable-analytics`.
- Configura el Android SDK con `flutter config --android-sdk <ruta>` una vez instalado.
- Próximos pasos sugeridos: añadir CI, configurar flavours, definir estilos/base UI.
