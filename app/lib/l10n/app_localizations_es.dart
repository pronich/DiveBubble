// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'DiveBubble';

  @override
  String get introSubtitle =>
      'Encuentra viajes de buceo, conoce a tus buddies y organiza la logística juntos.';

  @override
  String get diveIn => 'Entrar';

  @override
  String get skipForNow => 'Omitir por ahora';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get enterYourEmail => 'Introduce tu correo';

  @override
  String get enterCodeSentToYou => 'Introduce el código que te enviamos';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get continueWithEmail => 'Continuar con correo';

  @override
  String enterCodeSentTo(String email) {
    return 'Introduce el código enviado a $email';
  }

  @override
  String get verify => 'Verificar';

  @override
  String get useADifferentEmail => 'Usar otro correo';

  @override
  String get email => 'Correo electrónico';

  @override
  String get sendCode => 'Enviar código';

  @override
  String get useADifferentSignInMethod =>
      'Usar otro método de inicio de sesión';

  @override
  String get stayInTheLoop => 'Mantente al tanto';

  @override
  String get pushPermissionBody =>
      'Recibe avisos sobre nuevos mensajes, cambios en los viajes y quién se une a tus trayectos. Puedes desactivarlo cuando quieras en los ajustes del perfil.';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get notNow => 'Ahora no';

  @override
  String get addYourCertifications => 'Añade tus certificaciones';

  @override
  String get certificationsOnboardingBody =>
      'Tu nivel muestra a otros buceadores que estás listo para un viaje, y algunos viajes requieren un nivel mínimo para unirse. Puedes añadirlo o cambiarlo cuando quieras desde tu perfil.';

  @override
  String get level => 'Nivel';

  @override
  String get pleaseSelectALevel => 'Selecciona un nivel';

  @override
  String get selectLevel => 'Selecciona el nivel';

  @override
  String get agencyOptional => 'Agencia (opcional)';

  @override
  String get notSet => 'Sin definir';

  @override
  String get certificationNumberOptional =>
      'Número de certificación (opcional)';

  @override
  String get saveAndContinue => 'Guardar y continuar';
}
