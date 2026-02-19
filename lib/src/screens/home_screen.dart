import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../state/savi_state.dart';
import 'tabs/crear_tab.dart';
import 'tabs/perfil_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _codigoCtrl = TextEditingController();
  final FocusNode _codigoFocus = FocusNode();
  XFile? _qrImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<SaviState>(context, listen: false);
      state.cargarJuntas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: SvgPicture.asset('assets/logo2.svg', height: 56),
        actions: [
          IconButton(
            onPressed: () => state.logout(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: _buildBody(state),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Crear'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildBody(SaviState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentIndex) {
      case 0:
        return _buildTabInicio(state);
      case 1:
        return const CrearTab();
      case 2:
        return const PerfilTab();
      default:
        return Container();
    }
  }

  Widget _buildTabInicio(SaviState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _greetingCard(state),
          const SizedBox(height: 12),

          // Summary card (Juntas activas) - listen only to juntasActivas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Juntas activas',
                          style: Theme.of(context).textTheme.titleSmall),
                      Selector<SaviState, int>(
                        selector: (_, s) => s.juntasActivas,
                        builder: (_, juntasActivas, __) =>
                            Text('$juntasActivas'),
                      ),
                    ],
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Prompt
          Text('¿Que deberiamos hacer hoy?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              _actionButton(
                  'CREAR JUNTA', () => setState(() => _currentIndex = 1)),
              const SizedBox(width: 12),
              _actionButton('BUSCAR', () {
                setState(() => _currentIndex = 0);
                FocusScope.of(context).requestFocus(_codigoFocus);
              }),
            ],
          ),

          // Join section (inline Unirse)
          const SizedBox(height: 18),
          _unirseSection(state),
          const SizedBox(height: 20),

          // Mis Juntas header (fixed) and scrollable list below
          Text('Mis Juntas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // Only this list scrolls
          Expanded(
            child: Consumer<SaviState>(builder: (ctx, s, _) {
              final list = s.misJuntas;
              if (list.isEmpty)
                return const Center(child: Text('Aún no tienes juntas'));
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final junta = list[i];
                  return GestureDetector(
                    onTap: () async {
                      await s.seleccionarJunta(junta);
                      Navigator.pushNamed(context, '/detalles');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6F8), // soft pink background
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child:
                                const Icon(Icons.savings, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(junta.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                const SizedBox(height: 6),
                                Text(
                                    s.esDueno
                                        ? 'Eres el Organizador'
                                        : 'Participante',
                                    style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('S/ ${junta.montoCuota.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Eliminar junta'),
                                          content: const Text(
                                              '¿Seguro que quieres eliminar esta junta? Esta acción no se puede deshacer.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancelar')),
                                            ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Eliminar')),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await s.eliminarJunta(junta.id);
                                      }
                                    },
                                    icon: const Icon(Icons.delete_forever,
                                        color: Colors.redAccent, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.black54),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _greetingCard(SaviState state) {
    final user = state.currentUser;
    String name = 'Usuario';
    try {
      final meta =
          (user?.userMetadata ?? user?.user_metadata) as Map<String, dynamic>?;
      name = meta != null && (meta['nombre'] ?? meta['name']) != null
          ? (meta['nombre'] ?? meta['name']).toString()
          : (user?.email?.split('@').first ?? 'Usuario');
    } catch (_) {
      name = user?.email?.split('@').first ?? 'Usuario';
    }
    final roleText =
        state.rolActual == UserRole.owner ? 'Dueño' : 'Participante';

    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.waving_hand, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $name',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Rol actual: $roleText',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unirseSection(SaviState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Unirse a juntas',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codigoCtrl,
                focusNode: _codigoFocus,
                decoration: InputDecoration(
                  labelText: 'Código de la junta',
                  prefixIcon: const Icon(Icons.vpn_key, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                onPressed: _pickQrImage,
                child: const Icon(Icons.qr_code, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            if (_qrImage != null)
              SizedBox(
                width: 56,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_qrImage!.path), fit: BoxFit.cover),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
            ),
            onPressed: () => state.unirseAJunta(_codigoCtrl.text),
            child: const Text('Enviar solicitud'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickQrImage() async {
    try {
      final XFile? picked =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked != null) setState(() => _qrImage = picked);
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _codigoFocus.dispose();
    super.dispose();
  }

  Widget _actionButton(String label, VoidCallback onPressed) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.black,
      shape: const StadiumBorder(),
    );

    return Expanded(
      child: SizedBox(
        height: 44,
        child: ElevatedButton(
          style: style,
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}
