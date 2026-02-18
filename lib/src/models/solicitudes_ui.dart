class SolicitudUnirseUI {
  final String id;
  final String usuarioId;
  final String nombre;
  final String apellido;
  final String dni;
  final String telefono;
  final String correo;
  String estado;

  SolicitudUnirseUI({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.telefono,
    required this.correo,
    this.estado = 'pendiente',
  });
}

class SolicitudIntercambioUI {
  final String id;
  final String solicitanteId;
  final String solicitanteNombre;
  final String objetivoId;
  final String objetivoNombre;
  String estado;

  SolicitudIntercambioUI({
    required this.id,
    required this.solicitanteId,
    required this.solicitanteNombre,
    required this.objetivoId,
    required this.objetivoNombre,
    this.estado = 'pendiente',
  });
}
