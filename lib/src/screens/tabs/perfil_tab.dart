import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/savi_state.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PerfilTab extends StatefulWidget {
  const PerfilTab({super.key});

  @override
  State<PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<PerfilTab> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _inited = false;
  bool _editing = false;
  XFile? _pickedImage;
  bool _uploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = Provider.of<SaviState>(context, listen: false);
    if (!_inited) {
      _nombreCtrl.text = state.perfilNombre;
      _apellidoCtrl.text = state.perfilApellido;
      _dniCtrl.text = state.perfilDni;
      _telefonoCtrl.text = state.perfilTelefono;
      _inited = true;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _dniCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backendState = Provider.of<SaviState>(context, listen: false);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Mi perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (!_editing)
          Consumer<SaviState>(builder: (ctx, state, _) {
            return Column(
              children: [
                RepaintBoundary(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withAlpha((0.9 * 255).round()),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3E6),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: state.perfilAvatar.isNotEmpty
                                  ? Colors.transparent
                                  : Colors.orange,
                              backgroundImage: state.perfilAvatar.isNotEmpty
                                  ? NetworkImage(state.perfilAvatar)
                                      as ImageProvider
                                  : null,
                              child: state.perfilAvatar.isEmpty
                                  ? Text(
                                      ((state.perfilNombre.isNotEmpty
                                                  ? state.perfilNombre[0]
                                                  : '') +
                                              (state.perfilApellido.isNotEmpty
                                                  ? state.perfilApellido[0]
                                                  : ''))
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            children: [
                              Text(
                                state.perfilNombre.isNotEmpty
                                    ? '${state.perfilNombre} ${state.perfilApellido}'
                                        .trim()
                                    : '—',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              const Text('Miembro desde 2024',
                                  style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _nombreCtrl.text = state.perfilNombre;
                                      _apellidoCtrl.text = state.perfilApellido;
                                      _dniCtrl.text = state.perfilDni;
                                      _telefonoCtrl.text = state.perfilTelefono;
                                      setState(() => _editing = true);
                                    },
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Editar perfil'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Información Personal',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: Colors.blue.shade700),
                    ),
                    title: Text(state.perfilNombre.isNotEmpty
                        ? state.perfilNombre
                        : '—'),
                    subtitle: const Text('Nombre'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_outline,
                          color: Colors.indigo.shade700),
                    ),
                    title: Text(state.perfilApellido.isNotEmpty
                        ? state.perfilApellido
                        : '—'),
                    subtitle: const Text('Apellido'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.badge, color: Colors.green.shade700),
                    ),
                    title: Text(
                        state.perfilDni.isNotEmpty ? state.perfilDni : '—'),
                    subtitle: const Text('DNI'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.phone, color: Colors.teal.shade700),
                    ),
                    title: Text(state.perfilTelefono.isNotEmpty
                        ? state.perfilTelefono
                        : '—'),
                    subtitle: const Text('Teléfono'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          })
        else ...[
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: _pickedImage != null
                      ? FileImage(File(_pickedImage!.path))
                      : (backendState.perfilAvatar.isNotEmpty
                          ? NetworkImage(backendState.perfilAvatar)
                              as ImageProvider
                          : null),
                  child: (_pickedImage == null &&
                          backendState.perfilAvatar.isEmpty)
                      ? Icon(Icons.person,
                          size: 44, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final XFile? picked = await _picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 80);
                    if (picked != null) {
                      setState(() => _pickedImage = picked);
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cambiar foto'),
                ),
                const SizedBox(height: 8),
                if (_pickedImage != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _uploadingImage
                            ? null
                            : () async {
                                setState(() => _uploadingImage = true);
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  try {
                                    await backendState
                                        .subirAvatar(_pickedImage!.path);
                                    await backendState.cargarPerfil();
                                    if (!mounted) return;
                                    messenger.showSnackBar(const SnackBar(
                                        content: Text('Imagen cambiada')));
                                    setState(() => _pickedImage = null);
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                        SnackBar(content: Text('Error: $e')));
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _uploadingImage = false);
                                  }
                                }
                              },
                        icon: const Icon(Icons.check),
                        label: const Text('Aceptar imagen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _pickedImage = null);
                        },
                        child: const Text('Descartar'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
          TextField(
            controller: _nombreCtrl,
            decoration: InputDecoration(
                labelText: 'Nombre', prefixIcon: const Icon(Icons.person)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apellidoCtrl,
            decoration: InputDecoration(
                labelText: 'Apellido',
                prefixIcon: const Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dniCtrl,
            decoration: InputDecoration(
                labelText: 'DNI', prefixIcon: const Icon(Icons.badge)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telefonoCtrl,
            decoration: InputDecoration(
                labelText: 'Teléfono', prefixIcon: const Icon(Icons.phone)),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await backendState.guardarPerfil(
                        nombre: _nombreCtrl.text,
                        apellido: _apellidoCtrl.text,
                        dni: _dniCtrl.text,
                        telefono: _telefonoCtrl.text,
                      );
                      setState(() => _editing = false);
                    },
                    child: const Text('Guardar'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _editing = false);
                    },
                    child: const Text('Cancelar'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Deseas cerrar la sesión?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Cerrar sesión')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await backendState.logout();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ],
    );
  }
}
