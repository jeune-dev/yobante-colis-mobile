import 'package:flutter_test/flutter_test.dart';
import 'package:yobnate_colis/features/auth/data/models/user_model.dart';
import 'package:yobnate_colis/features/auth/domain/entities/user.dart';

/// VULN-L03 : Tests de sécurité — Entité User
void main() {
  group('UserModel — Sécurité des données', () {
    test('fromJson parse correctement les champs attendus', () {
      final json = {
        'utilisateur': {
          'id': 'abc123',
          'nom': 'Dupont',
          'prenom': 'Jean',
          'email': 'jean@example.com',
          'telephone': '0600000000',
          'role': 'client',
          'isActive': true,
        },
        'accessToken': 'tok_valid',
        'refreshToken': 'refresh_valid',
      };

      final model = UserModel.fromJson(json);
      expect(model.id, 'abc123');
      expect(model.nom, 'Dupont');
      expect(model.email, 'jean@example.com');
      expect(model.role, 'client');
      expect(model.accessToken, 'tok_valid');
    });

    test('fromJson ne stocke pas le mot de passe (VULN-C03)', () {
      final json = {
        'utilisateur': {
          'id': '1',
          'nom': 'D',
          'prenom': 'J',
          'email': 'j@e.com',
          'telephone': '0600000000',
          'role': 'client',
          'password': 'SECRET_HASH',        // envoyé par le serveur
          'mot_de_passe': 'AUTRE_SECRET',   // variante
        },
      };

      final model = UserModel.fromJson(json);
      // L'entité ne doit exposer aucun champ mot de passe
      expect((model as User).props.any((p) => p.toString().contains('SECRET')), false,
          reason: 'Le mot de passe ne doit jamais apparaître dans les props Equatable');
    });

    test('AuthResponseModel.fromJson parse accessToken et refreshToken', () {
      final json = {
        'data': {
          'accessToken': 'jwt_access',
          'refreshToken': 'jwt_refresh',
          'utilisateur': {
            'id': '1',
            'nom': 'D',
            'prenom': 'J',
            'email': 'j@e.com',
            'telephone': '0600000000',
            'role': 'client',
          },
        },
      };

      final response = AuthResponseModel.fromJson(json);
      expect(response.accessToken, 'jwt_access');
      expect(response.refreshToken, 'jwt_refresh');
      expect(response.user.email, 'j@e.com');
    });

    test('User.props ne contient que id, email, role — pas de données sensibles', () {
      final user = User(
        id: '1',
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean@example.com',
        telephone: '0600000000',
        role: 'client',
        accessToken: 'super_secret_jwt',
        refreshToken: 'super_secret_refresh',
      );

      // Seuls id, email et role participent à l'égalité Equatable
      expect(user.props, equals(['1', 'jean@example.com', 'client']));
      // Le token n'est pas dans props → ne fuite pas dans les logs BLoC
      expect(user.props.any((p) => p.toString().contains('secret')), false);
    });
  });
}
