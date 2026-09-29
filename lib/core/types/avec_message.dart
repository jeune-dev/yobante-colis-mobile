/// Résultat d'une action accompagnée du message du backend (champ `message` de
/// la réponse), destiné à être affiché tel quel à l'utilisateur.
typedef AvecMessage<T> = ({T valeur, String message});
