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
    // Buscamos el texto de la primera página del PageView
    expect(find.text('Bienvenido a SAVI'), findsOneWidget);

    // Verificar que el botón de "Iniciar sesión" existe
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Nota: No buscamos el contador '0' ni el icono '+' porque esta app no los tiene.
  });
}
