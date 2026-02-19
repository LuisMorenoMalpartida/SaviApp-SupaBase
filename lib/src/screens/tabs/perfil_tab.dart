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
          // Header card with avatar, name and edit button (design only)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // top accent
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3E6), // soft peach
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.orange,
                      child: Text(
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
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              // populate controllers and switch to edit mode
                              _nombreCtrl.text = state.perfilNombre;
                              _apellidoCtrl.text = state.perfilApellido;
                              _dniCtrl.text = state.perfilDni;
                              _telefonoCtrl.text = state.perfilTelefono;
                              setState(() => _editing = true);
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Editar perfil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.black,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Información Personal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          // Info cards with icons on the left
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.orange),
              ),
              title: Text(
                  state.perfilNombre.isNotEmpty ? state.perfilNombre : '—'),
              subtitle: const Text('Nombre'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: Colors.orange),
              ),
              title: Text(
                  state.perfilApellido.isNotEmpty ? state.perfilApellido : '—'),
              subtitle: const Text('Apellido'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.badge, color: Colors.orange),
              ),
              title: Text(state.perfilDni.isNotEmpty ? state.perfilDni : '—'),
              subtitle: const Text('DNI'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone, color: Colors.orange),
              ),
              title: Text(
                  state.perfilTelefono.isNotEmpty ? state.perfilTelefono : '—'),
              subtitle: const Text('Teléfono'),
            ),
          ),
          const SizedBox(height: 12),
          // small change photo button below info (kept text)
          // photo picker moved into edit mode
        ] else ...[
          // Edit mode: avatar + photo picker inside the form
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
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final XFile? picked = await _picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 80);
                    if (picked != null) {
                      final state =
                          Provider.of<SaviState>(context, listen: false);
                      final url = await state.subirAvatar(picked.path);
                      if (url != null) {
                        await state.cargarPerfil();
                      }
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cambiar foto'),
                ),
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
