/// REST-M02 : Ce fichier est conservé pour compatibilité mais
/// ne doit plus être utilisé directement — utiliser Env ou `sl<Dio>()`.
/// L'URL pointe désormais vers le backend actif Yobante Colis.
@Deprecated('Utiliser Env.baseUrl ou sl<Dio>() via injection_container')
class ApiConstants {
  @Deprecated('Utiliser Env.baseUrl')
  static const String baseUrl = 'http://10.0.2.2:9000';
}
