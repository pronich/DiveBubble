// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'DiveBubble';

  @override
  String get introSubtitle =>
      'Находите дайв-трипы, знакомьтесь с бадди и планируйте логистику вместе.';

  @override
  String get diveIn => 'Погрузиться';

  @override
  String get skipForNow => 'Пропустить';

  @override
  String get signIn => 'Войти';

  @override
  String get enterYourEmail => 'Введите вашу почту';

  @override
  String get enterCodeSentToYou => 'Введите код, который мы отправили';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get continueWithApple => 'Продолжить с Apple';

  @override
  String get continueWithEmail => 'Продолжить с почтой';

  @override
  String enterCodeSentTo(String email) {
    return 'Введите код, отправленный на $email';
  }

  @override
  String get verify => 'Подтвердить';

  @override
  String get useADifferentEmail => 'Использовать другую почту';

  @override
  String get email => 'Почта';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get useADifferentSignInMethod => 'Использовать другой способ входа';

  @override
  String get stayInTheLoop => 'Будьте в курсе';

  @override
  String get pushPermissionBody =>
      'Получайте уведомления о новых сообщениях, изменениях в трипах и о том, кто присоединяется к поездке. Это можно отключить в любой момент в настройках профиля.';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get addYourCertifications => 'Добавьте сертификации';

  @override
  String get certificationsOnboardingBody =>
      'Уровень показывает другим дайверам, что вы готовы к трипу, а для некоторых трипов требуется минимальный уровень. Изменить это можно в любой момент в профиле.';

  @override
  String get level => 'Уровень';

  @override
  String get pleaseSelectALevel => 'Пожалуйста, выберите уровень';

  @override
  String get selectLevel => 'Выберите уровень';

  @override
  String get agencyOptional => 'Агентство (необязательно)';

  @override
  String get notSet => 'Не указано';

  @override
  String get certificationNumberOptional => 'Номер сертификата (необязательно)';

  @override
  String get saveAndContinue => 'Сохранить и продолжить';
}
