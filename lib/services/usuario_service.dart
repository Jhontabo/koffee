import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String email;
  final String? nombre;
  final String rol;
  final DateTime fechaCreacion;
  final DateTime? ultimoLogin;

  Usuario({
    required this.id,
    required this.email,
    this.nombre,
    this.rol = 'usuario',
    required this.fechaCreacion,
    this.ultimoLogin,
  });

  factory Usuario.fromFirestore(String id, Map<String, dynamic> data) {
    return Usuario(
      id: id,
      email: data['email'] as String? ?? '',
      nombre: data['nombre'] as String?,
      rol: data['rol'] as String? ?? 'usuario',
      fechaCreacion: data['fechaCreacion'] != null
          ? DateTime.parse(data['fechaCreacion'] as String)
          : DateTime.now(),
      ultimoLogin: data['ultimoLogin'] != null
          ? DateTime.parse(data['ultimoLogin'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nombre': nombre,
      'rol': rol,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'ultimoLogin': ultimoLogin?.toIso8601String(),
    };
  }

  Usuario copyWith({
    String? id,
    String? email,
    String? nombre,
    String? rol,
    DateTime? fechaCreacion,
    DateTime? ultimoLogin,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ultimoLogin: ultimoLogin ?? this.ultimoLogin,
    );
  }
}

class UsuarioService {
  static final UsuarioService instance = UsuarioService._();
  final CollectionReference _usuariosCollection = FirebaseFirestore.instance
      .collection('usuarios');

  UsuarioService._();

  Future<Usuario?> getUsuario(String userId) async {
    try {
      final doc = await _usuariosCollection.doc(userId).get();
      if (doc.exists) {
        return Usuario.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting usuario: $e');
      return null;
    }
  }

  Future<void> crearUsuario({
    required String userId,
    required String email,
    String? nombre,
    String rol = 'usuario',
  }) async {
    try {
      final existente = await getUsuario(userId);
      if (existente != null) {
        await actualizarUltimoLogin(userId);
        return;
      }

      await _usuariosCollection.doc(userId).set({
        'email': email,
        'nombre': nombre ?? email.split('@').first,
        'rol': rol,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'ultimoLogin': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating usuario: $e');
    }
  }

  Future<void> actualizarUsuario({
    required String userId,
    String? nombre,
    String? rol,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;
      if (rol != null) updates['rol'] = rol;

      if (updates.isNotEmpty) {
        await _usuariosCollection.doc(userId).update(updates);
      }
    } catch (e) {
      print('Error updating usuario: $e');
    }
  }

  Future<void> actualizarUltimoLogin(String userId) async {
    try {
      await _usuariosCollection.doc(userId).update({
        'ultimoLogin': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating ultimo login: $e');
    }
  }

  Future<List<Usuario>> getAllUsuarios() async {
    try {
      final snapshot = await _usuariosCollection.get();
      return snapshot.docs
          .map(
            (doc) => Usuario.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting all usuarios: $e');
      return [];
    }
  }

  Future<void> eliminarUsuario(String userId) async {
    try {
      await _usuariosCollection.doc(userId).delete();
    } catch (e) {
      print('Error deleting usuario: $e');
    }
  }
}
