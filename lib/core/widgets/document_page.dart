import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../errors/api_error.dart';
import '../theme/app_color.dart';
import '../../injection_container.dart';
import 'empty_state.dart';
import 'toast_notif.dart';
import '../i18n/langue.dart';

/// Document imprimable renvoyé en HTML par le backend (étiquettes, bordereau,
/// facture, facture commerciale). Il est chargé avec le jeton du client (une
/// URL nue est refusée), affiché tel quel, et peut être partagé (email,
/// WhatsApp, impression depuis le navigateur ou l'imprimante du téléphone).
class DocumentPage extends StatefulWidget {
  final String titre;

  /// Chemin de l'API, relatif à l'URL de base (ex. `/client/colis/:id/etiquettes`).
  final String chemin;

  /// Nom du fichier proposé au partage.
  final String nomFichier;

  const DocumentPage({super.key, required this.titre, required this.chemin, required this.nomFichier});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  WebViewController? _controleur;
  String? _html;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _erreur = null;
      _html = null;
    });
    try {
      final res = await sl<Dio>().get<String>(
        widget.chemin,
        options: Options(responseType: ResponseType.plain, headers: {'Accept': 'text/html'}),
      );
      final html = res.data ?? '';
      final controleur = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..setBackgroundColor(Colors.white);
      await controleur.loadHtmlString(html);
      if (!mounted) return;
      setState(() {
        _html = html;
        _controleur = controleur;
      });
    } on DioException catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e, tr('Document indisponible')));
    }
  }

  Future<void> _partager() async {
    final html = _html;
    if (html == null) return;
    try {
      final dossier = await getTemporaryDirectory();
      final fichier = File('${dossier.path}/${widget.nomFichier}');
      await fichier.writeAsString(html);
      await SharePlus.instance.share(ShareParams(files: [XFile(fichier.path)], title: widget.titre));
    } catch (_) {
      if (mounted) {
        showToast(context, tr('Partage impossible'), tr('Réessayez dans un instant.'), ToastificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controleur = _controleur;
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        title: Text(widget.titre),
        actions: [
          if (controleur != null)
            IconButton(
              tooltip: tr('Partager ou imprimer'),
              icon: const Icon(Icons.ios_share),
              onPressed: _partager,
            ),
        ],
      ),
      body: _erreur != null
          ? EmptyState(
              icon: Icons.description_outlined,
              title: tr('Document indisponible'),
              subtitle: _erreur!,
              actionLabel: tr('Réessayer'),
              onAction: _charger,
            )
          : controleur == null
              ? const Center(child: CircularProgressIndicator())
              : WebViewWidget(controller: controleur),
    );
  }
}
