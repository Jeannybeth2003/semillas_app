/// Catálogo central de semillas disponibles en el juego.
/// Ajusta las rutas de `imagen` para que coincidan con las que ya usas
/// en `_obtenerImagenSemilla` dentro de la pantalla de siembra.
class SemillaInfo {
  final String id;
  final String nombre;
  final String imagen;

  const SemillaInfo({
    required this.id,
    required this.nombre,
    required this.imagen,
  });
}

const List<SemillaInfo> catalogoSemillas = [
  SemillaInfo(
    id: 'cacao',
    nombre: 'Cacao',
    imagen: 'assets/images/sprites/semilla_cacao.png',
  ),
  SemillaInfo(
    id: 'maiz',
    nombre: 'Maíz',
    imagen: 'assets/images/sprites/semilla_maiz.png',
  ),
  SemillaInfo(
    id: 'melon',
    nombre: 'Melón',
    imagen: 'assets/images/sprites/semilla_melon.png',
  ),
  SemillaInfo(
    id: 'patilla',
    nombre: 'Patilla',
    imagen: 'assets/images/sprites/semilla_patilla.png',
  ),
  SemillaInfo(
    id: 'platano',
    nombre: 'Plátano',
    imagen: 'assets/images/sprites/semilla_platano.png',
  ),
  SemillaInfo(
    id: 'yuca',
    nombre: 'Yuca',
    imagen: 'assets/images/sprites/semilla_yuca.png',
  ),
];

SemillaInfo semillaPorId(String id) {
  return catalogoSemillas.firstWhere(
    (s) => s.id == id,
    orElse: () => SemillaInfo(id: id, nombre: id, imagen: ''),
  );
}
