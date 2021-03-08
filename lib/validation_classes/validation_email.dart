import 'package:email_validator/email_validator.dart';
import "package:bikeinsthlm/login_related/login_screen.dart";

///Hela den här klassen hanterar validering av email och med email_validator
///paketet så kontrollerar den att input motsvarar korrekt email format.
///OBS. kontrollerar inte om domäner är giltiga eller inte dessvärre

class ValidateEmail {

  String validateEmail(String email) {
    if (email.isEmpty){
      return "Ange din e-post";
    }

    bool isValid = EmailValidator.validate(email);
    if (isValid){
      return null;
    } else {
      return "Ogiltig e-post";
    }
  }
}
