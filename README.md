<p align="center"><img src="assets/branding/sizesoul.svg" width="88" alt="SizeSoul"></p>
<h1 align="center">SizeSoul</h1>
<p align="center">Entiende tu disco. Recupera espacio con criterio.</p>
<p align="center"><a href="https://github.com/Litdemonick/SizeSoul/releases/latest">Descargar para Windows</a> · <a href="SECURITY.md">Seguridad</a> · <a href="CHANGELOG.md">Cambios</a></p>

SizeSoul es un explorador de almacenamiento de escritorio, en español y de código abierto. Hecho con Flutter y una integración nativa de Windows para la limpieza. No requiere una cuenta, servidor ni permisos de administrador.

## Instalar, actualizar y desinstalar

1. Descarga `SizeSoul-1.1.0-windows-x64-setup.exe` en **Releases**.
2. Ejecuta el instalador. Se instala para tu usuario en `%LOCALAPPDATA%\Programs\SizeSoul` y crea un acceso en Inicio. El acceso del escritorio es opcional.
3. Para actualizar, abre **Configuración → Buscar actualizaciones**. La consulta es manual. Descarga y ejecuta el nuevo instalador: conserva la carpeta, la configuración y el historial. Se bloquea instalar una versión semántica anterior.
4. Desinstala desde **Configuración de Windows → Aplicaciones → SizeSoul**. El desinstalador retira los archivos instalados y los accesos directos, pero conserva tu base local. Su ruta aparece en la configuración de la app.

También hay un ZIP portable: extrae **todo** su contenido y abre `sizesoul.exe`. No copies únicamente el EXE. Instalador y portable incluyen el runtime de Visual C++ para la aplicación. Windows 10 1809 o posterior de 64 bits; Windows 11 compatible. La app se compila para x64.

Los binarios todavía **no tienen firma Authenticode** y Windows puede mostrar una advertencia de reputación. Comprueba el origen y los hashes SHA-256 publicados; los hashes no sustituyen la firma de un editor.

## Qué hace

- Detecta unidades montadas: capacidad, espacio libre, etiqueta y sistema de archivos.
- Analiza carpetas o unidades en un isolate cancelable, sin bloquear el hilo de Flutter durante el escaneo.
- Muestra carpetas, mapa proporcional navegable y los 200 archivos más grandes, con filtro por nombre/ruta/extensión.
- Envía archivos individuales a la Papelera tras confirmación y validación nativa. El espacio se libera al vaciarla desde Windows.
- Abre las herramientas de Windows para desinstalar aplicaciones, limpiar temporales y gestionar particiones/formato.
- Guarda preferencias e historial acotado en SQLite, con transacciones y versión de esquema.
- Incluye temas claro/oscuro, icono propio, ventana con límites según DPI/monitor y una sola instancia por sesión.
- Muestra la versión instalada y consulta versiones estables de este repositorio solo cuando lo pides.

## Protecciones y límites reales

La limpieza bloquea raíces, carpetas sensibles (Windows, Program Files, ProgramData, AppData, recuperación, metadatos del disco y credenciales conocidas), archivos ocultos/de sistema, enlaces y archivos con varios enlaces físicos. Valida tamaño y fecha contra el análisis y comprueba de nuevo en C++ antes de solicitar a Windows el envío a la Papelera. Solo permite archivos normales de volúmenes locales fijos. No hay borrado permanente, borrado de carpetas, borrado por lotes ni vaciado automático.

Estas protecciones reducen errores; **ninguna aplicación garantiza seguridad total** ni decide si tus documentos son prescindibles. Un proceso hostil que cambia archivos concurrentemente no forma parte de la garantía. Conserva copias y revisa cada archivo. Las operaciones realizadas en herramientas externas de Windows tienen sus propias confirmaciones y riesgos.

El tamaño mostrado es lógico, no el espacio asignado exacto. Permisos, archivos del sistema, compresión, enlaces físicos y cambios durante el escaneo pueden causar diferencias frente a Windows. No se lee la MFT y no se promete la velocidad de WizTree. Se conservan los agregados de carpetas y una lista acotada de archivos grandes; una carpeta individual con millones de entradas todavía puede consumir bastante memoria. El filtro se aplica a los 200 archivos retenidos, no al disco completo.

No implementa borrado seguro de discos, formateo propio, búsqueda de duplicados por contenido ni desinstalación por lotes. El formato rápido **no** es un borrado seguro.

## Privacidad

Sin telemetría. SQLite guarda hasta 100 resúmenes y preferencias, no un índice completo. Las consultas manuales a GitHub comparten IP y datos HTTP normales, pero nunca rutas ni resultados. El botón de versiones abre el navegador; no hay descargas ni ejecución automática de actualizaciones.

## Desarrollo

Requisitos: Flutter **3.47.1**, Dart **3.13.1**, Visual Studio con desarrollo de escritorio C++ e Inno Setup 6.7 o posterior para el instalador.

```powershell
flutter pub get
flutter run -d windows
flutter analyze
flutter test
flutter build windows --release
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-release.ps1
```

`build-release.ps1` valida el proyecto, compila Flutter, incorpora las bibliotecas redistribuibles de Visual C++, genera el instalador y ZIP y escribe sus SHA-256 en `dist/`. Puedes indicar `-InnoCompiler 'ruta\ISCC.exe'`. La opción de política de ejecución solo afecta ese proceso de PowerShell; no cambia la política global.

La versión se define una sola vez en `pubspec.yaml` (`major.minor.patch+build`). El ejecutable, el panel de versiones y el instalador la leen desde los metadatos de compilación. No cambies el `AppId` del instalador ni el mutex entre versiones.

| Directorio | Responsabilidad |
| --- | --- |
| `lib/app` | Tema y composición inicial |
| `lib/core/models`, `security`, `storage` | Modelos, reglas de rutas y SQLite |
| `lib/features/scan` | Motor de análisis y mapa |
| `lib/features/dashboard/widgets` | Unidades y paneles reutilizables |
| `lib/features/disks` | Información e integración con Windows |
| `lib/features/updates` | Versión instalada y consulta de releases |
| `lib/shared/widgets` | Componentes e identidad visual |
| `windows/runner/storage_guard.*` | Validación y Papelera nativa |
| `installer`, `scripts` | Instalador, iconos y empaquetado |
| `test`, `.github/workflows` | Pruebas y compilación automatizada |

La licencia del código propio es MIT. Flutter y las dependencias conservan sus licencias; los redistribuibles de Microsoft se distribuyen bajo sus términos. Consulta [CONTRIBUTING.md](CONTRIBUTING.md) y [SECURITY.md](SECURITY.md) antes de cambiar las operaciones de limpieza.
