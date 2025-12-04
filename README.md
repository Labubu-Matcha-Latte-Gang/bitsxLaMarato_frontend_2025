# bitsxLaMarato_frontend_2025

Aplicación Flutter del frontend para BitsXMarató 2025.

## Stack del proyecto
- Flutter 3.27.1 (Dart 3.5+)
- Construcción web con Docker y nginx
- Tests iniciales en `test/widget_test.dart`
- Configuración multi-plataforma (Android, iOS, Web, Windows, Linux y macOS)

## Requisitos previos
1. **Docker Desktop** instalado y funcionando
2. **PowerShell** (incluido en Windows)

### Para desarrollo local (opcional)
- **Flutter SDK** disponible en el PATH (`flutter --version`)
- **Java 11-19** recomendado para Android (considera Temurin 17)
- **Android Studio** (para Android SDK/AVD) o dispositivo físico
- Plugins Flutter/Dart en tu editor favorito

## 🚀 Puesta en marcha rápida (Docker)

### Opción 1: Script automático (recomendado)
```powershell
# Ejecuta el gestor interactivo
.\start.ps1
```

El script `start.ps1` proporciona un menú interactivo con las siguientes opciones:
- **Opción 1**: Construir y ejecutar preview (automáticamente abre http://localhost:8080)
- **Opción 2**: Detener preview
- **Opción 3**: Salir y limpiar contenedores

### Opción 2: Comandos manuales
```powershell
# Construir y ejecutar con Docker Compose
docker-compose up -d --build

# Ver en el navegador
# http://localhost:8080

# Detener el contenedor
docker-compose down
```

## Desarrollo local sin Docker

Si prefieres trabajar directamente con Flutter:

```powershell
# 1) Diagnóstico del entorno
flutter doctor

# 2) Instalar dependencias
flutter pub get

# 3) Ejecutar tests
flutter test

# 4) Ejecutar en modo desarrollo (web)
flutter run -d chrome

# 5) Ejecutar en otros dispositivos
flutter devices                 # Lista dispositivos disponibles
flutter run -d android         # Android (emulador o dispositivo)
flutter run -d windows         # Windows (aplicación nativa)
```

## Configuración del proyecto

### Variables de entorno
El proyecto permite configurar la URL de la API mediante la variable `API_URL`:

```powershell
# Ejemplo con API personalizada
$env:API_URL="https://mi-api.ejemplo.com"
docker-compose up -d --build
```

Por defecto usa `http://localhost:5000` si no se especifica.

### Arquitectura Docker
- **Build Stage**: Usa imagen oficial de Flutter 3.27.1 para compilar la app web
- **Runtime Stage**: nginx alpine para servir los archivos estáticos
- **Puerto**: Expone el puerto 8080 para acceder a la aplicación
- **Cache**: Configuración de nginx optimizada para desarrollo (sin cache en archivos JS/JSON)

## Estructura del proyecto
| Ruta | Descripción |
| --- | --- |
| `start.ps1` | **Script principal** - Gestor interactivo para Docker |
| `docker-compose.yml` | Configuración de servicios Docker |
| `Dockerfile` | Construcción multi-stage con Flutter + nginx |
| `nginx.conf` | Configuración del servidor web nginx |
| `lib/main.dart` | Punto de entrada Flutter |
| `pubspec.yaml` | Dependencias y configuración del proyecto |
| `test/widget_test.dart` | Tests automatizados |
| `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` | Targets nativos |

## Comandos útiles

### Docker
```powershell
# Ver logs del contenedor
docker logs flutter_local_preview

# Entrar al contenedor (debug)
docker exec -it flutter_local_preview sh

# Reconstruir sin cache
docker-compose build --no-cache
docker-compose up -d
```

### Flutter (desarrollo)
```powershell
# Análisis de código
flutter analyze

# Formateo de código
flutter format .

# Limpiar y reconstruir
flutter clean
flutter pub get

# Hot reload en desarrollo
flutter run -d chrome --hot
```

## Troubleshooting

### Error de puertos
Si el puerto 8080 está ocupado, modifica `docker-compose.yml`:
```yaml
ports:
  - "3000:80"  # Cambia 8080 por 3000 o el puerto que prefieras
```

### Problemas con Docker
```powershell
# Limpiar contenedores y volúmenes
docker system prune -a

# Verificar que Docker está funcionando
docker --version
docker-compose --version
```

### Flutter no encontrado
Si trabajas sin Docker, asegúrate de que Flutter está en el PATH:
```powershell
# Verificar instalación
flutter --version
flutter doctor

# Agregar al PATH de la sesión actual
$env:Path += ';C:\tools\flutter\bin'
```

## Próximos pasos
- [ ] Configurar CI/CD con GitHub Actions
- [ ] Definir flavours (dev/staging/prod)
- [ ] Implementar sistema de diseño base
- [ ] Configurar análisis estático avanzado
- [ ] Integrar testing automatizado en Docker
