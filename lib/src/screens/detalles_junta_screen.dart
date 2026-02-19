import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';

class DetallesJuntaScreen extends StatefulWidget {
  const DetallesJuntaScreen({super.key});

  @override
  State<DetallesJuntaScreen> createState() => _DetallesJuntaScreenState();
}

class _DetallesJuntaScreenState extends State<DetallesJuntaScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = Provider.of<SaviState>(context, listen: false);
    if (state.juntaSeleccionada != null) {
      // Ejecutar después del frame para evitar marcar widgets durante el build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) state.cargarDetallesJunta(state.juntaSeleccionada!.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    if (state.juntaSeleccionada == null) {
      return const Scaffold(body: Center(child: Text('Seleccione una junta')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title:
            Text(state.nombreJunta.isNotEmpty ? state.nombreJunta : 'Detalles'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepOrange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Organizador + Monto
              Row(
                children: [
                  Expanded(
                    child: Text('Organizador:',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.deepOrange)),
                  ),
                  // small avatar icon top-right
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.handshake_rounded),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Monto centered
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Monto de la junta',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                          color: Colors.white,
                        ),
                        child: Text(state.montoJunta,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Responsive grid of cards using Wrap to avoid overflow
              LayoutBuilder(builder: (context, constraints) {
                final double spacing = 16;
                final double totalSpacing = spacing; // between two columns
                final double cardWidth =
                    (constraints.maxWidth - totalSpacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildCard(
                        context,
                        title: 'Detalles',
                        subtitle:
                            'Consulta aquí todos los detalles de tu junta.',
                        icon: Icons.article_outlined,
                        onTap: () {},
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildCard(
                        context,
                        title: 'Invitar más amigos',
                        subtitle:
                            'Invita a tus amigos compartiendo tu ID de usuario.',
                        icon: Icons.qr_code_scanner,
                        onTap: () {},
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildCard(
                        context,
                        title: 'Integrantes y pagos',
                        subtitle:
                            'Registra en tiempo real los pagos de cada integrante.',
                        icon: Icons.list_alt,
                        onTap: () => Navigator.pushNamed(context, '/pagos'),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildCard(
                        context,
                        title: 'Reportar',
                        subtitle:
                            'Informa sobre cualquier integrante que no cumpla con su cuota.',
                        icon: Icons.report_problem_outlined,
                        onTap: () {},
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // Footer info: codigo y participantes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Código: ${state.codigoJunta}'),
                  Text('Participantes: ${state.numPersonas}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 28, color: Colors.deepOrange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
