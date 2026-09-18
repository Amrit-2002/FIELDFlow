import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isFieldWorker => role.toUpperCase() == 'FIELD_WORKER';

  @override
  List<Object?> get props => [id, name, email, role];
}

