import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/savi_state.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = Provider.of<SaviState>(context);
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
    final state = Provider.of<SaviState>(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Mi perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (!_editing) ...[
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: state.perfilAvatar.isNotEmpty
                      ? NetworkImage(state.perfilAvatar) as ImageProvider
                      : null,
                  child: state.perfilAvatar.isEmpty
                      ? const Icon(Icons.person, size: 44, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    final XFile? picked = await _picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 80);
                    if (picked != null) {
                      // upload immediately via SaviState helper
                      final state =
                          Provider.of<SaviState>(context, listen: false);
                      final url = await state.subirAvatar(picked.path);
                      if (url != null) {
                        // reload perfil
                        await state.cargarPerfil();
                      }
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cambiar foto'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text(
                  state.perfilNombre.isNotEmpty ? state.perfilNombre : '—'),
              subtitle: const Text('Nombre'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(
                  state.perfilApellido.isNotEmpty ? state.perfilApellido : '—'),
              subtitle: const Text('Apellido'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(state.perfilDni.isNotEmpty ? state.perfilDni : '—'),
              subtitle: const Text('DNI'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(
                  state.perfilTelefono.isNotEmpty ? state.perfilTelefono : '—'),
              subtitle: const Text('Teléfono'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                // populate controllers and switch to edit mode
                _nombreCtrl.text = state.perfilNombre;
                _apellidoCtrl.text = state.perfilApellido;
                _dniCtrl.text = state.perfilDni;
                _telefonoCtrl.text = state.perfilTelefono;
                setState(() => _editing = true);
              },
              child: const Text('Editar perfil'),
            ),
          ),
        ] else ...[
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () async {
                      await state.guardarPerfil(
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
                      // cancel edit
                      setState(() => _editing = false);
                    },
                    child: const Text('Cancelar'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
