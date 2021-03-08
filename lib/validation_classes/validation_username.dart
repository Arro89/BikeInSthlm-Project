/// Validerar användarnamn, kontrollerar att det inte är mer än 15 tecken eller
/// tomt. Dock behöver det införas att kontroller att användarnamnet inte finns
/// redan i databasen.

class ValidateUsername {

  String validateUserName(String username) {
    if (username.isEmpty) {
      return "Ange ditt namn";
    }

    Pattern pattern = r"^[A-Za-z0-9]+(?:[ _-][A-Za-z0-9]+)*$";
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(username)) {
      return "Ogiltigt format på användarnamnet";
    } else if (username.length > 20) {
      return "Användarnamn får max innehålla 20 tecken";
    } else {
      return null;
    }
  }
}