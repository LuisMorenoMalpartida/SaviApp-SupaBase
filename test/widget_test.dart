import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:savi_app/src/app.dart';
import 'package:savi_app/src/state/savi_state.dart';

void main() {
  testWidgets('SaviApp smoke test', (WidgetTester tester) async {
    // Construir la app envolviéndola en el Provider, igual que en main.dart
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SaviState(),
        child: const SaviApp(),
      ),
    );

    // Verificar que la pantalla de bienvenida carga correctamente
    // Buscamos el botón principal de la pantalla de bienvenida
    expect(find.text('COMENZAR AHORA'), findsOneWidget);

    // Nota: No buscamos el contador '0' ni el icono '+' porque esta app no los tiene.
  });
}
