import 'package:firebase_database/firebase_database.dart';

class FirebaseRealtimeService {
  static final _db = FirebaseDatabase.instance;

  static DatabaseReference kioscoRef(String id) =>
      _db.ref('kioscos/$id');

  // ── Streams en tiempo real ──────────────────────────────────────────────

  static Stream<GestoDetectado?> gestoStream(String kioscoId) {
    return kioscoRef(kioscoId).child('gesto').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;
      final map = Map<String, dynamic>.from(data as Map);
      return GestoDetectado(
        texto: map['texto'] as String? ?? '',
        confianza: (map['confianza'] as num?)?.toDouble() ?? 0.0,
        timestamp: map['timestamp'] as int? ?? 0,
      );
    });
  }

  static Stream<String> mensajeTFTStream(String kioscoId) {
    return kioscoRef(kioscoId)
        .child('mensaje_tft')
        .onValue
        .map((e) => e.snapshot.value?.toString() ?? '');
  }

  static Stream<String> estadoStream(String kioscoId) {
    return kioscoRef(kioscoId)
        .child('estado')
        .onValue
        .map((e) => e.snapshot.value?.toString() ?? 'offline');
  }

  // ── Escritura ───────────────────────────────────────────────────────────

  static Future<void> enviarFrase(String kioscoId, String frase) async {
    await kioscoRef(kioscoId).update({
      'frase_usuario': frase,
      'timestamp_frase': ServerValue.timestamp,
    });
  }

  static Future<void> setAppConectada(String kioscoId, bool value) async {
    await kioscoRef(kioscoId).update({
      'app_conectada': value,
      'ultimo_acceso': ServerValue.timestamp,
    });
  }

  static Future<bool> kioscoExiste(String kioscoId) async {
    final snap = await kioscoRef(kioscoId).get();
    return snap.exists;
  }

  static Future<Map<String, dynamic>?> getKiosco(String kioscoId) async {
    final snap = await kioscoRef(kioscoId).get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  static Stream<List<KioscoInfo>> kioscosActivosStream() {
    return _db.ref('kioscos').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final data =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map? ?? {});
        return KioscoInfo(
          id: e.key,
          nombre: v['nombre'] as String? ?? 'Kiosco HandWave',
          direccion: v['direccion'] as String? ?? '',
          estado: v['estado'] as String? ?? 'offline',
          distancia: (v['distancia'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    });
  }
}

// ── Modelos ─────────────────────────────────────────────────────────────────

class GestoDetectado {
  final String texto;
  final double confianza;
  final int timestamp;

  const GestoDetectado({
    required this.texto,
    required this.confianza,
    required this.timestamp,
  });

  bool get esValido => confianza >= 0.75 && texto.isNotEmpty;
  String get confianzaPct => '${(confianza * 100).toInt()}%';
}

class KioscoInfo {
  final String id;
  final String nombre;
  final String direccion;
  final String estado;
  final int distancia;

  const KioscoInfo({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.estado,
    required this.distancia,
  });

  bool get isOnline => estado == 'online';
  String get distanciaTexto => distancia < 1000
      ? '${distancia}m'
      : '${(distancia / 1000).toStringAsFixed(1)}km';
}