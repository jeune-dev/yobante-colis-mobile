import 'package:dio/dio.dart';
import '../../../core/config/env.dart';
import '../../../core/errors/api_error.dart';
import '../../../core/i18n/langue.dart';

/// Formulaire « Nous contacter » (`POST /public/demandes-contact`), accessible
/// sans compte : la demande arrive au support, qui répond par email.
class ContactRemoteDataSource {
  final Dio dio;
  ContactRemoteDataSource({required this.dio});

  /// Site d'origine attendu par le backend : « rek » pour Yobante Colis.
  static const source = 'rek';

  /// Renvoie le message du backend.
  Future<String> envoyer({
    required String prenom,
    required String nom,
    required String email,
    String? telephone,
    String? sujet,
    required String message,
  }) =>
      appelApi(() async {
        final res = await dio.post(
          Env.publicDemandesContact,
          data: {
            'source': source,
            'prenom': prenom.trim(),
            'nom': nom.trim(),
            'email': email.trim(),
            if (telephone != null && telephone.trim().isNotEmpty) 'telephone': telephone.trim(),
            if (sujet != null && sujet.trim().isNotEmpty) 'sujet': sujet.trim(),
            'message': message.trim(),
          },
          options: Options(extra: {'skipAuthInterceptor': true}),
        );
        return messageApi(res);
      }, tr('Envoi de votre message impossible'));
}
