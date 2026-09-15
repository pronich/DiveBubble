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

  @override
  String errorWithMessage(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get you => 'Вы';

  @override
  String get diver => 'Дайвер';

  @override
  String get searchBubbles => 'Поиск по Bubbles';

  @override
  String get noMatches => 'Совпадений нет.';

  @override
  String get share => 'Поделиться';

  @override
  String get documentFallbackName => 'Документ.pdf';

  @override
  String get copiedToClipboard => 'Скопировано';

  @override
  String get deleteThisMessageTitle => 'Удалить это сообщение?';

  @override
  String get deleteThisMessageBody =>
      'Это необратимо — сообщение будет удалено для всех в этом Bubble.';

  @override
  String couldNotDeleteMessage(String error) {
    return 'Не удалось удалить сообщение: $error';
  }

  @override
  String couldNotReact(String error) {
    return 'Не удалось поставить реакцию: $error';
  }

  @override
  String get reply => 'Ответить';

  @override
  String get copyText => 'Скопировать текст';

  @override
  String get report => 'Пожаловаться';

  @override
  String get removeDocumentFirst =>
      'Сначала удалите документ, чтобы добавить фото.';

  @override
  String onlyNAttachmentsAllowed(int max) {
    return 'В одном сообщении можно отправить не более $max вложений.';
  }

  @override
  String get documentOnlyOnItsOwn =>
      'Документ можно отправить только отдельно.';

  @override
  String get someFilesTooLarge => 'Некоторые файлы слишком большие.';

  @override
  String couldNotSendAttachment(String error) {
    return 'Не удалось отправить вложение: $error';
  }

  @override
  String get noMessagesYet => 'Пока нет сообщений';

  @override
  String get tripCancelledReadOnly =>
      'Этот трип отменён — чат доступен только для чтения.';

  @override
  String replyingTo(String name) {
    return 'Ответ для $name';
  }

  @override
  String get captionOptional => 'Подпись (необязательно)';

  @override
  String get messageHint => 'Сообщение';

  @override
  String get messageDeleted => 'Сообщение удалено';

  @override
  String attachmentsCountLabel(int count) {
    return '📎 $count вложений';
  }

  @override
  String get photoLabel => '📷 Фото';

  @override
  String get videoLabel => '🎬 Видео';

  @override
  String get pdfLabel => '📄 PDF';

  @override
  String get newMessages => 'Новые сообщения';

  @override
  String get productObserver => 'Product Observer';

  @override
  String get reportMessageTitle => 'Пожаловаться на сообщение';

  @override
  String get detailsOptional => 'Подробности (необязательно)';

  @override
  String get sendReport => 'Отправить жалобу';

  @override
  String get reportSentThankYou => 'Жалоба отправлена — спасибо.';

  @override
  String couldNotSendReport(String error) {
    return 'Не удалось отправить жалобу: $error';
  }

  @override
  String get thankYou => 'Спасибо!';

  @override
  String get giveFeedback => 'Оставить отзыв';

  @override
  String get howUsefulQuestion =>
      'Насколько полезен был DiveBubble для этого трипа?';

  @override
  String get whatDidHelpQuestion => 'В чём вам помог DiveBubble?';

  @override
  String get whatShouldImproveQuestion => 'Что нам стоит улучшить?';

  @override
  String get optionalHintText => 'Необязательно';

  @override
  String get canContactAboutFeedback =>
      'Можем ли мы связаться с вами по поводу отзыва?';

  @override
  String get submitFeedback => 'Отправить отзыв';

  @override
  String couldNotSendFeedback(String error) {
    return 'Не удалось отправить отзыв: $error';
  }

  @override
  String get reportReasonSpam => 'Спам';

  @override
  String get reportReasonHarassment => 'Домогательства';

  @override
  String get reportReasonInappropriateContent => 'Неприемлемый контент';

  @override
  String get reportReasonOther => 'Другое';

  @override
  String get helpedWithTripInformation => 'Информация о трипе';

  @override
  String get helpedWithChattingWithParticipants => 'Общение с участниками';

  @override
  String get helpedWithFindingTransport => 'Поиск транспорта';

  @override
  String get helpedWithFindingBuddy => 'Поиск бадди';

  @override
  String get helpedWithNothingYet => 'Пока ничего';

  @override
  String couldNotSharePhoto(String error) {
    return 'Не удалось поделиться фото: $error';
  }

  @override
  String couldNotShareVideo(String error) {
    return 'Не удалось поделиться видео: $error';
  }

  @override
  String get couldNotLoadVideo => 'Не удалось загрузить видео';

  @override
  String couldNotLoadMedia(String error) {
    return 'Не удалось загрузить медиа: $error';
  }

  @override
  String get noPhotosOrVideosSharedYet => 'Пока нет фото или видео';

  @override
  String couldNotLoadFiles(String error) {
    return 'Не удалось загрузить файлы: $error';
  }

  @override
  String get noFilesSharedYet => 'Пока нет файлов';

  @override
  String couldNotLoadLinks(String error) {
    return 'Не удалось загрузить ссылки: $error';
  }

  @override
  String get noLinksSharedYet => 'Пока нет ссылок';

  @override
  String get shareToABubble => 'Поделиться в Bubble';

  @override
  String get noBubblesYet => 'Пока нет Bubbles';

  @override
  String get joinATripToShareInto =>
      'Присоединитесь к трипу, чтобы получить Bubble, в который можно поделиться.';

  @override
  String get bubblesTabTitle => 'Bubbles';

  @override
  String get diveLogTabTitle => 'Дневник';

  @override
  String get profileTabTitle => 'Профиль';

  @override
  String get signInToSeeYourTrips => 'Войдите, чтобы увидеть свои трипы';

  @override
  String get logInToViewTripsBody =>
      'Войдите, чтобы увидеть трипы, к которым вы присоединились, и их групповые чаты.';

  @override
  String get startYourFirstBubble => 'Начните свой первый Bubble';

  @override
  String get startYourFirstBubbleBody =>
      'Создайте трип или присоединитесь по коду — чат, транспорт и детали трипа в одном месте.';

  @override
  String get createTrip => 'Создать трип';

  @override
  String get joinTrip => 'Присоединиться';

  @override
  String get chatTabLabel => 'Чат';

  @override
  String get transportTabLabel => 'Транспорт';

  @override
  String get buddyTabLabel => 'Бадди';

  @override
  String get expensesTabLabel => 'Расходы';

  @override
  String get archive => 'В архив';

  @override
  String get unarchive => 'Из архива';

  @override
  String get cancelTrip => 'Отменить трип';

  @override
  String get leave => 'Покинуть';

  @override
  String couldNotArchive(String error) {
    return 'Не удалось архивировать: $error';
  }

  @override
  String couldNotUnarchive(String error) {
    return 'Не удалось разархивировать: $error';
  }

  @override
  String get leaveBubbleTitle => 'Покинуть этот Bubble?';

  @override
  String get leaveBubbleBody =>
      'Вы потеряете своё место и сможете присоединиться позже, если будут места.';

  @override
  String couldNotLeave(String error) {
    return 'Не удалось покинуть: $error';
  }

  @override
  String get cancelTripTitle => 'Отменить этот трип?';

  @override
  String get cancelTripBody =>
      'У всех участников останется доступ к истории чата, но никто — включая вас — не сможет отправлять сообщения, присоединяться или организовывать транспорт. Это необратимо.';

  @override
  String get neverMind => 'Не сейчас';

  @override
  String couldNotCancel(String error) {
    return 'Не удалось отменить: $error';
  }

  @override
  String get cancelledStatus => 'Отменён';

  @override
  String get pastStatus => 'Прошёл';

  @override
  String get activeStatus => 'Активен';

  @override
  String get archivedChats => 'Архивные чаты';

  @override
  String get noArchivedChats => 'Нет архивных чатов';

  @override
  String get archivedChatsEmptyBody =>
      'Bubbles, которые вы архивируете, появятся здесь — смахните или разархивируйте, чтобы вернуть обратно.';
}
