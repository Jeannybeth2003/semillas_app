# 🌱 Semillas de Identidad

**Semillas de Identidad** es una aplicación móvil interactiva desarrollada en Flutter, diseñada para conectar a los niños de la Amazonia Venezolana con la riqueza cultural, la flora y la fauna de la región amazónica. Cuenta con una interfaz vibrante, navegación intuitiva y una experiencia inmersiva orientada en formato horizontal (landscape).

---

## 🛠 Requisitos Previos

Antes de comenzar, asegúrate de tener instalados los siguientes componentes en tu máquina:

* **Flutter SDK:** (Versión estable más reciente).
* **Android Studio:** Para la gestión de SDKs de Android y herramientas de compilación.
* **Emulador de Android o Dispositivo Físico:** Para probar la aplicación.
* **Git:** Para el control de versiones.

---

## 🚀 Instalación y Configuración

Sigue estos pasos para levantar el proyecto en tu entorno local:

**1. Clonar el repositorio:**
```bash
git clone https://github.com/Inesc28/semillas_app
cd semillas_app
```

**2. Descargar las dependencias:**
```bash
flutter pub get
```

---

## 📱 Ejecutar el Proyecto

1. Asegúrate de tener un emulador abierto o un dispositivo físico conectado con la depuración USB habilitada.
2. Verifica que el dispositivo aparece en la lista de Flutter:
```bash
flutter devices
```
3. Ejecuta la aplicación:
```bash
flutter run
```

---

## 🏗 Estructura del Proyecto

El proyecto sigue una arquitectura limpia y modular para facilitar el trabajo en equipo:

* `assets/`: Contiene todos los recursos estáticos.
    * `images/`: Fondos (ej. `Conuco_bg.webp`), íconos y personajes.
    * `audio/`: Pistas de sonido y efectos (usamos formato `.ogg` nativo para loops perfectos en juegos).
* `lib/`: Directorio principal del código fuente.
    * `layouts/`: Componentes reutilizables, como `base_layout.dart` que mantiene la consistencia del fondo y la estructura base.
    * `views/screens/`: Pantallas de la aplicación (`start_screen.dart`, `village_screen.dart`, etc.).
    * `main.dart`: Punto de entrada de la app, donde se fuerza la orientación horizontal (`landscapeLeft`, `landscapeRight`).

---

## ⚠️ Solución de Problemas Frecuentes 

Durante el desarrollo pueden surgir bloqueos comunes. Si experimentas errores, revisa esta lista:

### 1. Error de compilación por `ndkVersion`
Si la app no compila en Android debido a un error con el NDK, asegúrate de que el archivo `android/app/build.gradle` (o `build.gradle.kts`) tenga la versión correcta configurada en el bloque `android { ... }` (ej. `ndkVersion = "27.0.12077973"`).

### 2. Bloqueo de archivos (Error de permisos o caché)
Es común que algunos archivos se bloqueen impidiendo la compilación, especialmente si hubo una ejecución cancelada abruptamente. Si ves un error de acceso denegado o "Unable to delete directory", limpia la caché del proyecto:
```bash
flutter clean
flutter pub get
```

---

## 📦 Compilación (Build)

Para generar el archivo APK final y distribuirlo para pruebas en dispositivos reales, ejecuta:

```bash
flutter build apk --release
```

El archivo generado se encontrará en la ruta: `build/app/outputs/flutter-apk/app-release.apk`.
