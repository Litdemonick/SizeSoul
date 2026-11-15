import 'package:path/path.dart' as p;

/// Fast UI preflight. The native operation independently revalidates the file.
class PathPolicy {
  static const protectedParts = {
    'windows',
    'program files',
    'program files (x86)',
    'programdata',
    'appdata',
    r'$recycle.bin',
    'system volume information',
    'recovery',
    'boot',
    'efi',
    'msocache',
    '.git',
    '.ssh',
    '.aws',
    '.codex',
    '.agents',
  };
  static String? reason(String path) {
    if (!RegExp(r'^[a-zA-Z]:\\').hasMatch(path) ||
        path.contains(':', 2) ||
        path.contains('/') ||
        path.contains('\u0000')) {
      return 'Solo se admiten rutas locales absolutas sin alias.';
    }
    final parts = path.substring(3).toLowerCase().split('\\');
    if (parts.length < 2) return 'Los archivos en la raíz están protegidos.';
    if (parts.any(
      (part) =>
          part.isEmpty ||
          part == '.' ||
          part == '..' ||
          part.endsWith('.') ||
          part.endsWith(' ') ||
          protectedParts.contains(part),
    )) {
      return 'Ruta sensible, de sistema o ambigua. Limpieza bloqueada.';
    }
    if (p.windows.normalize(path) != path) {
      return 'La ruta debe estar normalizada.';
    }
    return null;
  }
}
