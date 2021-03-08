/// Klassen validerar telefonnummer så formatet stämmer
/// Får skriva tydligare dokumentation sen

class ValidatePhoneNr{

  String validatePhoneNr(String phoneNr) {
    if (phoneNr.isEmpty) {
      return "Ange ditt telefonnummer";
    }

    phoneNr = removePermittedPunctuation(phoneNr);
    if (!isNumeric(phoneNr)) {
      return "Telefonnumret är inte numeriskt";
    }


    if (!phoneNr.startsWith("0") || phoneNr.startsWith("+")) {
      return "Felaktigt format på telefonnumret";
    }

    if (phoneNr.length != 10 &&
        (phoneNr.startsWith("0") || phoneNr.startsWith("+"))) {
      return "Telefonnumret är för kort";
    }
  }

  ///PhoneValidation methods
  String removePermittedPunctuation(String str) => str
      .split("")
      .where((ch) => ![".", " ", "(", ")", "-", "+"].contains(ch))
      .fold("", (str, elem) => str + elem);

  bool isDigit(String ch) =>
      ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"].contains(ch);

  bool isNumeric(String str) => str.split("").every(isDigit);

}