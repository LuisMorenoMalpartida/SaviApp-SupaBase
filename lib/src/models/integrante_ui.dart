class IntegranteUI {
  String id;
  String nombre;
  String usuario;
  String dni;
  String telefono;
  String correo;
  String numero;
  bool ocupado;
  bool pagoRealizado;
  String? voucherUrl;

  IntegranteUI({
    this.id = '',
    this.nombre = 'Cupo Disponible',
    this.usuario = 'Toque para editar',
    this.dni = '',
    this.telefono = '',
    this.correo = '',
    this.numero = '',
    this.ocupado = false,
    this.pagoRealizado = false,
    this.voucherUrl,
  });
}
