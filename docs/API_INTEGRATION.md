# API Integration - Patient Registration

## Descripción
Se ha implementado la integración con el endpoint `/api/v1/user/patient` para el registro de pacientes en la aplicación Flutter.

## Archivos creados/modificados:

### 1. `lib/models/patient_models.dart`
- **PatientRegistrationRequest**: Modelo para enviar datos de registro
- **PatientRegistrationResponse**: Modelo para recibir respuesta del servidor
- **PatientRole**: Modelo para los datos específicos del rol de paciente
- **ApiError**: Modelo para manejar errores de la API

### 2. `lib/services/api_service.dart`
- **ApiService.registerPatient()**: Método para registrar pacientes
- **ApiException**: Excepción personalizada para errores de API
- Manejo completo de códigos de error HTTP (400, 404, 422, 500)

### 3. `lib/features/screens/register/registerPacient.dart`
- Integración completa con la API
- Validaciones mejoradas para campos numéricos
- Dropdown para selección de sexo (male/female)
- Indicador de carga durante el registro
- Diálogos de éxito y error
- Validaciones de formulario completas

## Funcionalidades implementadas:

### ✅ Validaciones de formulario
- **Diagnóstico**: Campo obligatorio
- **Sexe**: Dropdown con opciones "Home" (male) y "Dona" (female)
- **Tractament**: Campo obligatorio
- **Edat**: Validación numérica (0-150 años)
- **Altura**: Validación numérica con decimales (50-250 cm)
- **Pes**: Validación numérica con decimales (20-500 kg)
- **Nom i Cognom**: Campos obligatorios
- **Email**: Validación de formato
- **Password**: Campo obligatorio

### ✅ Integración con API
- **Endpoint**: POST `/api/v1/user/patient`
- **Headers**: `Content-Type: application/json`
- **Body**: JSON con todos los datos del paciente
- **Respuesta 201**: Registro exitoso
- **Respuestas de error**: 400, 404, 422, 500 manejadas correctamente

### ✅ UX/UI mejoradas
- Indicador de carga en el botón de registro
- Diálogos informativos para éxito y error
- Validación en tiempo real de formulario
- Hints en campos numéricos
- Campos deshabilitados durante la carga

## Configuración

### URL de la API
La URL base se configura en `lib/config.dart`:
```dart
class Config {
  static const String apiUrl = String.fromEnvironment(
    'API_URL', 
    defaultValue: 'http://localhost:5000'
  );
}
```

### Dependencias añadidas
En `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
```

## Uso

1. El usuario completa los 3 pasos del formulario
2. Al presionar "REGISTER" en el último paso:
   - Se validan todos los campos
   - Se muestra indicador de carga
   - Se envía petición HTTP POST a la API
   - Se muestra resultado (éxito o error)
   - En caso de éxito, se navega de vuelta

## Estructura de datos enviados a la API

```json
{
  "name": "Clara",
  "surname": "Puig", 
  "email": "clara.puig@example.com",
  "password": "ClaraSegura1",
  "ailments": "Asma",
  "gender": "female", 
  "age": 28,
  "treatments": "Inhalador diari",
  "height_cm": 168.5,
  "weight_kg": 64.3,
  "doctors": []
}
```

## Respuesta esperada de la API

```json
{
  "email": "clara.puig@example.com",
  "name": "Clara",
  "surname": "Puig",
  "role": {
    "ailments": "Asma",
    "gender": "female",
    "age": 28,
    "treatments": "Inhalador diari", 
    "height_cm": 168.5,
    "weight_kg": 64.3,
    "doctors": []
  }
}
```

## Manejo de errores

- **400**: "Falta un camp obligatori o el correu ja està registrat"
- **404**: "No s'ha trobat cap correu de metge indicat"
- **422**: "El cos de la sol·licitud no ha superat la validació"
- **500**: "Error inesperat del servidor en crear el pacient"
- **Conexión**: "Error de connexió amb el servidor"

## Próximos pasos

1. **Campo doctors**: Implementar selector de médicos (actualmente vacío)
2. **Autenticación**: Agregar JWT tokens si es necesario
3. **Offline support**: Manejo de modo sin conexión
4. **Retry logic**: Reintentos automáticos en caso de error temporal