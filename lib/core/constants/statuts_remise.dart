/// Statuts où le colis peut être remis au destinataire : l'agent génère un code,
/// le destinataire le saisit. Partagés pour que les deux côtés restent d'accord.
const kStatutsRemise = ['disponible_retrait', 'en_livraison'];

/// Statuts qui attestent que le destinataire a bien reçu son colis.
const kStatutsRemis = ['recupere', 'livre'];
