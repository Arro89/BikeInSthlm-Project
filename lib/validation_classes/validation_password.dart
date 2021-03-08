/// För validering av lösenord.
/// validateStructure kollar att det finns minst 1 versal, 1 gemen och
/// 1 specialtecken i lösenordet.
///
/// validatePassword metoden kollar om input är tomt, mindre än 10 tecken
/// och anropar validateStructure metoden

class ValidatePassword {

  bool validateStructure(String password) {
    Pattern passwordPattern =
        r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$";
    RegExp regExp = new RegExp(passwordPattern);
    return regExp.hasMatch(password);
  }

  String validatePassword(String password) {
    if (password.isEmpty) {
      return "Ange ditt lösenord";
    }

    if (password.length < 10) {
      return "Lösenordet måste vara minst 10 tecken långt";
    }

    bool validPassword = validateStructure(password);
    if (!validPassword) {
      return "Behöver minst en gemen, versal och ett specialtecken";
    } else {
      return null;
    }
  }
}
