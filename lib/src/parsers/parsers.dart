import '../models/integrante_ui.dart';
import '../models/solicitudes_ui.dart';

List<IntegranteUI> parseIntegrantes(Map<String, dynamic> args) {
  final List<dynamic> data = args['data'] ?? [];
  final int numPersonas = args['numPersonas'] ?? 0;

  final list = data.map((p) {
    final perfil = (p['perfiles'] ?? {}) as Map<String, dynamic>;
    return IntegranteUI(
      id: p['usuario_id'] ?? '',
      nombre: "${perfil['nombre'] ?? ''} ${perfil['apellido'] ?? ''}".trim(),
      usuario: p['rol'] == 'dueño' ? 'Administrador' : 'Miembro',
      dni: perfil['dni'] ?? '',
      telefono: perfil['telefono'] ?? '',
      correo: '',
      numero: p['numero_turno']?.toString() ?? '',
      ocupado: true,
      pagoRealizado: p['pago_realizado'] ?? false,
      voucherUrl: p['voucher_url'],
    );
  }).toList();

  while (list.length < numPersonas) {
    list.add(IntegranteUI());
  }

  return list;
}

List<SolicitudUnirseUI> parseSolicitudes(List<dynamic> data) {
  return data.map((s) {
    final perfil = (s['perfiles'] ?? {}) as Map<String, dynamic>;
    return SolicitudUnirseUI(
      id: s['id'],
      usuarioId: s['usuario_id'],
      nombre: perfil['nombre'] ?? '',
      apellido: perfil['apellido'] ?? '',
      dni: perfil['dni'] ?? '',
      telefono: perfil['telefono'] ?? '',
      correo: '',
      estado: s['estado'] ?? 'pendiente',
    );
  }).toList();
}
