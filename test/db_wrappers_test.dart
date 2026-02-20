import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:savi_app/backend.dart' as backend;

// Simple fake Supabase client used for testing wrappers in lib/db.dart
class FakeQuery implements Future<dynamic> {
  final dynamic _result;
  late final Future _future;
  FakeQuery(this._result) {
    _future = _result is Future ? _result as Future : Future.value(_result);
  }

  // Make eq/filter/select chainable by returning a FakeQuery wrapper that
  // delegates to the same underlying result.
  FakeQuery eq(String key, dynamic value) => FakeQuery(_result);
  FakeQuery filter(String a, String b, dynamic c) => FakeQuery(_result);
  FakeQuery select([dynamic _]) => FakeQuery(_result);

  Future<dynamic> maybeSingle() async {
    final res = await _future;
    if (res is List && res.isEmpty) return null;
    if (res is List) return res.first;
    return res;
  }

  Future<dynamic> insert(Map<String, dynamic> payload) =>
      Future.value([payload]);
  Future<dynamic> update(Map<String, dynamic> payload) =>
      Future.value([payload]);

  // Future implementation - delegate to internal future
  @override
  Stream asStream() => _future.asStream();

  @override
  Future catchError(Function onError, {bool Function(Object)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic) onValue,
          {Function? onError}) =>
      _future.then<R>(onValue, onError: onError as dynamic);

  @override
  Future whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Future timeout(Duration timeLimit,
          {FutureOr<dynamic> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);
}

class FakeFromBuilder {
  final String table;
  final dynamic result;
  FakeFromBuilder(this.table, this.result);
  FakeQuery select([dynamic x]) => FakeQuery(result);
  FakeQuery insert(Map<String, dynamic> payload) => FakeQuery([payload]);
  FakeQuery update(Map<String, dynamic> payload) => FakeQuery([payload]);
  FakeQuery delete() => FakeQuery([]);
  FakeQuery order(String a, {bool ascending = true}) => FakeQuery(result);
  FakeQuery limit(int n) => FakeQuery(result);
}

// Failing builder that simulates missing column error on first update with pago_realizado
class FakeFromBuilderFail42703 extends FakeFromBuilder {
  bool _first = true;
  FakeFromBuilderFail42703(super.table, super.result);

  @override
  FakeQuery update(Map<String, dynamic> payload) {
    if (_first && payload.containsKey('pago_realizado')) {
      _first = false;
      return FakeQuery(() async {
        throw Exception('column "pago_realizado" does not exist (42703)');
      }());
    }
    return FakeQuery([payload]);
  }
}

class CustomClient extends FakeSupabaseClient {
  CustomClient(super.data);
  @override
  FakeFromBuilder from(String table) {
    if (table == 'participantes') return _builder;
    return super.from(table);
  }

  final FakeFromBuilderFail42703 _builder =
      FakeFromBuilderFail42703('participantes', []);
}

// Builder that throws on update to simulate a DB error
class FakeFromBuilderThrow extends FakeFromBuilder {
  FakeFromBuilderThrow(super.table, super.result);
  @override
  FakeQuery update(Map<String, dynamic> payload) =>
      FakeQuery(() async => throw Exception('update failed'));
}

class CustomClient2 extends FakeSupabaseClient {
  CustomClient2(super.data);
  @override
  FakeFromBuilder from(String table) {
    if (table == 'solicitudes') return _builder;
    return super.from(table);
  }

  final FakeFromBuilderThrow _builder = FakeFromBuilderThrow('solicitudes', []);
}

class FakeSupabaseClient {
  final Map<String, dynamic> data;
  FakeSupabaseClient(this.data);
  // Minimal `auth` shim expected by backend.SaviState constructor
  FakeAuth get auth => FakeAuth();
  FakeFromBuilder from(String table) {
    return FakeFromBuilder(table, data[table] ?? []);
  }
}

class FakeAuth {
  // backend.SaviState listens to onAuthStateChange; provide an empty stream.
  Stream get onAuthStateChange => const Stream.empty();
}

void main() {
  group('DB wrappers', () {
    test('obtenerParticipantesPorJunta returns list', () async {
      final fake = FakeSupabaseClient({
        'participantes': [
          {'usuario_id': 'u1', 'id': 'p1'},
        ]
      });
      backend.setSupabaseClient(fake);

      final res = await backend.SaviState().obtenerParticipantesPorJunta('j1');
      expect(res, isA<List<dynamic>>());
      expect(res.length, 1);
      expect(res.first['usuario_id'], 'u1');
    });

    test('obtenerPerfilesPorIds returns profiles', () async {
      final fake = FakeSupabaseClient({
        'perfiles': [
          {'id': 'u1', 'nombre': 'Luis', 'apellido': 'M'},
        ]
      });
      backend.setSupabaseClient(fake);

      final res = await backend.SaviState().obtenerPerfilesPorIds(['u1']);
      expect(res, isA<List<dynamic>>());
      expect(res.first['nombre'], 'Luis');
    });

    test('obtenerSolicitudesPorJunta returns solicitudes', () async {
      final fake = FakeSupabaseClient({
        'solicitudes': [
          {'id': 's1', 'usuario_id': 'u1', 'estado': 'pendiente'}
        ]
      });
      backend.setSupabaseClient(fake);

      final res = await backend.SaviState().obtenerSolicitudesPorJunta('j1');
      expect(res, isA<List<dynamic>>());
      expect(res.first['estado'], 'pendiente');
    });

    test('insertarParticipante and actualizarSolicitudEstado run without error',
        () async {
      final fake = FakeSupabaseClient({
        'participantes': [],
        'solicitudes': [
          {'id': 's1', 'usuario_id': 'u1', 'estado': 'pendiente'}
        ]
      });
      backend.setSupabaseClient(fake);

      // should not throw
      await backend.SaviState().insertarParticipante('j1', 'u1');
      await backend.SaviState().actualizarSolicitudEstado('s1', 'aprobada');
    });

    test(
        'actualizarParticipanteVoucher retries when pago_realizado column missing',
        () async {
      // Use the top-level CustomClient which simulates the missing-column on first update
      final customClient = CustomClient({'participantes': []});
      backend.setSupabaseClient(customClient);

      // Should not throw even if initial update fails due to missing column
      await backend.SaviState().actualizarParticipanteVoucher('j1', 'u1',
          pagoRealizado: true, voucherUrl: 'http://x');
    });

    test('actualizarSolicitudEstado rethrows on DB error', () async {
      final client = CustomClient2({'solicitudes': []});
      backend.setSupabaseClient(client);
      try {
        await backend.SaviState().actualizarSolicitudEstado('s1', 'aprobada');
        fail('expected exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}
