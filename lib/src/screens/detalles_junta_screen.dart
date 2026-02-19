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
        title: Text(state.nombreJunta.isNotEmpty ? state.nombreJunta : 'Detalles'),
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
              // Organizer card
              RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (state.perfilNombre.isNotEmpty ? state.perfilNombre[0] : 'U').toUpperCase(),
                            style: TextStyle(
                                color: Colors.deepPurple.shade700,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.perfilNombre.isNotEmpty
                                ? '${state.perfilNombre} ${state.perfilApellido}'.trim()
                                : 'Usuario Principal'),
                            const SizedBox(height: 4),
                            Text('Creador de la junta', style: TextStyle(color: Colors.black.withOpacity(0.56))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Large amount card with gradient
              RepaintBoundary(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [Colors.deepOrange.shade400, Colors.orange.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.shade100.withOpacity(0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.show_chart, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text('Monto de la junta', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(state.montoJunta, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Total acumulado', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Grid of feature cards (fixed height to keep uniform sizes)
              LayoutBuilder(builder: (context, constraints) {
                final double spacing = 14;
                final double cardWidth = (constraints.maxWidth - spacing) / 2;
                // increase card height to avoid content overflow on small devices
                final double cardHeight = cardWidth * 0.9; // slightly taller
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: RepaintBoundary(
                        child: _featureCard(
                          context,
                          title: 'Detalles',
                          subtitle: 'Consulta para recibir los detalles de tu junta',
                          icon: Icons.article_outlined,
                          color: Colors.blue.shade50,
                          iconColor: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: RepaintBoundary(
                        child: _featureCard(
                          context,
                          title: 'Invitar más amigos',
                          subtitle: 'Comparte tu junta con tus amigos de confianza',
                          icon: Icons.person_add,
                          color: Colors.green.shade50,
                          iconColor: Colors.green.shade700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: RepaintBoundary(
                        child: _featureCard(
                          context,
                          title: 'Integrantes y pagos',
                          subtitle: 'Registra los tiempos hasta los pagos de cada usuario',
                          icon: Icons.group,
                          color: Colors.yellow.shade50,
                          iconColor: Colors.amber.shade700,
                          onTap: () => Navigator.pushNamed(context, '/pagos'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: RepaintBoundary(
                        child: _featureCard(
                          context,
                          title: 'Reportar',
                          subtitle: 'Informa sobre cualquier miembro que incumple la cuota',
                          icon: Icons.flag,
                          color: Colors.red.shade50,
                          iconColor: Colors.red.shade700,
                        ),
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

  Widget _featureCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      Color? color,
      Color? iconColor,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color ?? Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: iconColor ?? Colors.deepOrange),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
