<div align="center">
  <img src="assets/logos/logo-text-blau.png" alt="logo" width="200" height="auto" />
  <h1>bitsxLaMarató 2025 - Frontend</h1>
  
  <p>
    Frontend de l'aplicació per a la gestió de pacients i activitats, desenvolupat per a l'esdeveniment BitsxLaMarató 2025.
  </p>
  
  <h4>
    <a href="https://github.com/Labubu-Matcha-Latte-Gang/bitsxLaMarato_frontend_2025/issues/">Informar d'un error</a>
    <span> · </span>
    <a href="https://github.com/Labubu-Matcha-Latte-Gang/bitsxLaMarato_frontend_2025/issues/">Sol·licitar una funcionalitat</a>
    <span> · </span>
    <a href="https://github.com/Labubu-Matcha-Latte-Gang/bitsxLaMarato_frontend_2025/pulls">Contribuir</a>
  </h4>
</div>

<br />

## Sobre el Projecte

Aquest repositori conté el codi font del client (frontend) per a l'aplicació de **bitsxLaMarató 2025**. L'objectiu principal és proporcionar una interfície d'usuari intuïtiva i accessible perquè pacients i metges puguin interactuar amb el sistema de seguiment de la salut en el context de La Marató de TV3.

L'aplicació està construïda amb Flutter, la qual cosa permet la seva execució en múltiples plataformes (web, Windows, Linux, macOS) a partir d'una única base de codi.

### Tecnologies principals

*   **Flutter 3.x**: Framework principal per al desenvolupament multiplataforma.
*   **Dart**: Llenguatge de programació utilitzat per Flutter.
*   **http**: Per a la comunicació amb l'API REST del backend.
*   **provider**: Per a la gestió de l'estat de l'aplicació.
*   **flutter_test**: Per a la realització de tests de widgets i unitaris.

## Com començar

Per poder executar el projecte en un entorn de desenvolupament local, segueix els passos següents.

### Prerequisits

Assegura't de tenir instal·lat el següent programari:
*   **Flutter SDK**: Versió 3.19 o superior. Pots seguir la [guia oficial d'instal·lació](https://docs.flutter.dev/get-started/install).
*   Un editor de codi com [Visual Studio Code](https://code.visualstudio.com/) amb l'extensió de Flutter, o [Android Studio](https://developer.android.com/studio).
*   Per a desenvolupament d'escriptori, les eines de compilació necessàries per al teu sistema operatiu (Visual Studio per a Windows, eines de compilació de C++ per a Linux).

### Instal·lació

1.  **Clona el repositori**
    ```bash
    git clone https://github.com/Labubu-Matcha-Latte-Gang/bitsxLaMarato_frontend_2025.git
    cd bitsxLaMarato_frontend_2025
    ```

2.  **Obté les dependències**
    Executa la següent comanda per descarregar totes les dependències del projecte:
    ```bash
    flutter pub get
    ```

3.  **Configuració de l'entorn**
    Crea un fitxer `lib/config.dart` a partir de `lib/config.example.dart` i ajusta la variable `apiUrl` perquè apunti a la instància del backend que estiguis utilitzant.

## Ús

Pots executar l'aplicació en diferents plataformes. Assegura't de tenir un dispositiu o emulador disponible (`flutter devices`).

### Execució per a Web

```bash
flutter run -d chrome
```

### Execució per a Escriptori (Windows, macOS, Linux)

Primer, assegura't que el suport per a escriptori estigui habilitat a Flutter:
```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

Després, executa l'aplicació:
```bash
flutter run -d windows
# O -d macos, -d linux
```

## Tests

Per executar la suite de tests de widgets, utilitza la següent comanda:

```bash
flutter test
```

Això executarà tots els tests definits al directori `test/`.

## Documentació de l'API

Aquesta aplicació consumeix l'API del backend. Pots trobar la documentació interactiva de l'API (Swagger UI) a l'endpoint `/api/docs` del servidor del backend. Si el backend s'executa localment, l'URL seria:

[http://localhost:5000/api/docs](http://localhost:5000/api/docs)

## Llicència

Distribuït sota la Llicència GPL-3.0. Consulta el fitxer `LICENSE` per a més informació.
