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

  @override
  String get typeOfferRide => 'Предлагаю место в машине';

  @override
  String get typeShareRental => 'Делюсь арендой';

  @override
  String get carCancelledByOrganizer =>
      'Эта машина была отменена организатором.';

  @override
  String get noTransportWasArranged => 'Транспорт не был организован';

  @override
  String get beFirstToShareTransport =>
      'Будьте первым, кто поделится транспортом';

  @override
  String get tripCancelledSimple => 'Этот трип отменён.';

  @override
  String get offerRideOrShareRental =>
      'Предложите место в машине или поделитесь арендой, чтобы к вам могли присоединиться.';

  @override
  String get addTransportInfo => 'Добавить транспорт';

  @override
  String seatsTakenLabel(int joined, int total) {
    return 'Занято $joined из $total мест';
  }

  @override
  String get joinedStatus => 'Участвую';

  @override
  String get fullStatus => 'Мест нет';

  @override
  String get organizerLabel => 'Организатор';

  @override
  String get organizerYou => 'Организатор · Вы';

  @override
  String get joinedDivers => 'Участники';

  @override
  String get noOneHasJoinedYet => 'Пока никто не присоединился';

  @override
  String get cancelCarOffer => 'Отменить машину';

  @override
  String get leaveCar => 'Покинуть машину';

  @override
  String get join => 'Присоединиться';

  @override
  String get seatsOptional => 'Мест (необязательно)';

  @override
  String get detailsTimePickupOptional =>
      'Детали — время, место встречи (необязательно)';

  @override
  String get add => 'Добавить';

  @override
  String get buddyGroupCancelledByOrganizer =>
      'Эта группа бадди была отменена организатором.';

  @override
  String get noBuddyRequestsWereMade => 'Запросов на бадди не было';

  @override
  String get beFirstToLookForBuddy => 'Будьте первым, кто ищет бадди';

  @override
  String get requestBuddySoOthersCanJoin =>
      'Оставьте запрос на бадди, чтобы другие могли присоединиться к вам для этого дайва.';

  @override
  String get requestABuddy => 'Найти бадди';

  @override
  String get buddyRequestTitle => 'Запрос на бадди';

  @override
  String divesCountLabel(int count) {
    return '$count погружений';
  }

  @override
  String get creatorLabel => 'Создатель';

  @override
  String get creatorYou => 'Создатель · Вы';

  @override
  String get groupLabel => 'Группа';

  @override
  String get cancelBuddyRequest => 'Отменить запрос';

  @override
  String get leaveBuddyGroup => 'Покинуть группу';

  @override
  String get otherDiversWillSeeRequest =>
      'Другие дайверы на этом трипе увидят ваш запрос и смогут присоединиться.';

  @override
  String get request => 'Отправить';

  @override
  String get about => 'О приложении';

  @override
  String versionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get gearLockerTitle => 'Снаряжение';

  @override
  String ownedOfTotalInLocker(int owned, int total) {
    return '$owned/$total в наличии';
  }

  @override
  String get clearCacheTitle => 'Очистить кэш?';

  @override
  String get clearCacheBody =>
      'Это удалит скачанные фото и файлы с этого устройства. В самих чатах трипов ничего не удаляется — файлы просто скачаются заново при следующем открытии.';

  @override
  String get clear => 'Очистить';

  @override
  String get cacheCleared => 'Кэш очищен.';

  @override
  String couldNotClearCache(String error) {
    return 'Не удалось очистить кэш: $error';
  }

  @override
  String get storageTitle => 'Хранилище';

  @override
  String get clearCacheRow => 'Очистить кэш';

  @override
  String get clearCacheSubtitle =>
      'Удаляет скачанные фото и файлы чатов с этого устройства';

  @override
  String couldNotUnblock(String error) {
    return 'Не удалось разблокировать: $error';
  }

  @override
  String get blockedUsersTitle => 'Заблокированные';

  @override
  String get noBlockedUsers => 'Нет заблокированных пользователей.';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get copyEmailAddress => 'Скопировать адрес почты';

  @override
  String get emailAddressCopied => 'Адрес почты скопирован';

  @override
  String get legalTitle => 'Правовая информация';

  @override
  String get termsOfService => 'Условия использования';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get contactSupport => 'Связаться с поддержкой';

  @override
  String get addADive => 'Добавить дайв';

  @override
  String get updateLevelTitle => 'Изменить уровень';

  @override
  String get save => 'Сохранить';

  @override
  String get addSpeciality => 'Добавить специализацию';

  @override
  String get specialityName => 'Название специализации';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get pushNotificationsLabel => 'Push-уведомления';

  @override
  String get pushDisabledInSystemSettings =>
      'Отключены в системных настройках — сначала включите уведомления DiveBubble там';

  @override
  String get tapToEnableNotifications => 'Нажмите, чтобы включить уведомления';

  @override
  String get newMessagesTripUpdatesEtc =>
      'Новые сообщения, изменения в трипах и многое другое';

  @override
  String get verified => 'Подтверждено';

  @override
  String get addCertificate => 'Добавить сертификат';

  @override
  String get blockThisUserTitle => 'Заблокировать этого пользователя?';

  @override
  String get blockUserBody =>
      'Вы больше не будете видеть его сообщения в общих чатах трипов. Отменить это можно в Профиль → Заблокированные.';

  @override
  String get block => 'Заблокировать';

  @override
  String get blockUserTooltip => 'Заблокировать пользователя';

  @override
  String get blockedManageBody =>
      'Заблокирован. Управление — в Профиль → Заблокированные.';

  @override
  String couldNotBlockUser(String error) {
    return 'Не удалось заблокировать пользователя: $error';
  }

  @override
  String get bioLabel => 'О себе';

  @override
  String get divesLabel => 'Погружения';

  @override
  String get languagesLabel => 'Языки';

  @override
  String get memberSinceLabel => 'В приложении с';

  @override
  String get editProfileTitle => 'Редактировать профиль';

  @override
  String get displayNameLabel => 'Отображаемое имя';

  @override
  String get displayNameHelper =>
      'Показывается другим дайверам вместо настоящего имени';

  @override
  String get pleaseEnterDisplayName => 'Пожалуйста, введите отображаемое имя';

  @override
  String get locationLabel => 'Местоположение';

  @override
  String get useCurrentLocationTooltip => 'Использовать текущее местоположение';

  @override
  String get unloggedDivesLabel => 'Незалогированные погружения';

  @override
  String get unloggedDivesHelper =>
      'Погружения, которых нет в вашем дневнике — учитываются вместе с ним в общем счёте';

  @override
  String get allDivesAreLogged => 'Все мои погружения в дневнике';

  @override
  String get selectLanguages => 'Выберите языки';

  @override
  String get zeroOutUnloggedDivesTitle =>
      'Обнулить незалогированные погружения?';

  @override
  String get zeroOutUnloggedDivesBody =>
      'Это обнулит число выше. Записи в дневнике не затрагиваются — меняется только вручную введённое число.';

  @override
  String get zeroOut => 'Обнулить';

  @override
  String get editDiveTitle => 'Изменить дайв';

  @override
  String get addDiveTitle => 'Добавить дайв';

  @override
  String get importedDiveLockedNotice =>
      'Этот дайв импортирован с компьютера для дайвинга — редактировать можно только страну, место и заметки.';

  @override
  String get dateLabel => 'Дата';

  @override
  String get timeLabel => 'Время';

  @override
  String get maxDepthLabel => 'Макс. глубина';

  @override
  String get avgDepthLabel => 'Средняя глубина';

  @override
  String get durationLabel => 'Продолжительность';

  @override
  String get minTemperatureLabel => 'Мин. температура';

  @override
  String get minTempLabel => 'Мин. темп.';

  @override
  String get maxTempLabel => 'Макс. темп.';

  @override
  String get countryLabel => 'Страна';

  @override
  String get diveSiteLabel => 'Место погружения';

  @override
  String get notesLabel => 'Заметки';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get deleteThisDiveTitle => 'Удалить этот дайв?';

  @override
  String get cantBeUndone => 'Это необратимо.';

  @override
  String get gearEssentialSection => 'ОСНОВНОЕ';

  @override
  String get gearAdditionalSection => 'ДОПОЛНИТЕЛЬНОЕ';

  @override
  String get addItem => 'Добавить предмет';

  @override
  String get gearOwned => 'Есть';

  @override
  String get gearMissing => 'Нет';

  @override
  String get gearUsuallyRent => 'Обычно в аренду';

  @override
  String get addItemSheetBody =>
      'Для всего, что не входит в основной список — фонарь, экшн-камера, буй...';

  @override
  String get itemNameLabel => 'Название предмета';

  @override
  String get gearItemBoots => 'Ботинки';

  @override
  String get gearItemFins => 'Ласты';

  @override
  String get gearItemBcd => 'BCD';

  @override
  String get gearItemWetsuitShorty5mm => 'Гидрокостюм shorty 5мм';

  @override
  String get gearItemWetsuit5mm => 'Гидрокостюм 5мм';

  @override
  String get gearItemWetsuit7mm => 'Гидрокостюм 7мм';

  @override
  String get gearItemWetsuit9mm => 'Гидрокостюм 9мм';

  @override
  String get gearItemSemidrySuit => 'Полусухой костюм';

  @override
  String get gearItemDrySuit => 'Сухой костюм';

  @override
  String get gearItemHelmet => 'Шлем';

  @override
  String get gearItemGloves => 'Перчатки';

  @override
  String get gearItemRegulator => 'Регулятор';

  @override
  String get gearItemComputer => 'Компьютер';

  @override
  String get gearItemMask => 'Маска';

  @override
  String get shareToBubble => 'Поделиться в Bubble';

  @override
  String get sourceLabel => 'Источник';

  @override
  String get importedValue => 'Импортировано';

  @override
  String get manualValue => 'Вручную';

  @override
  String diveOnDate(String date) {
    return 'Дайв $date';
  }

  @override
  String labelColonValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get sharedToBubble => 'Отправлено в Bubble';

  @override
  String couldNotShare(String error) {
    return 'Не удалось поделиться: $error';
  }

  @override
  String get haventJoinedAnyBubblesYet =>
      'Вы пока не присоединились ни к одному Bubble.';

  @override
  String selectedCountLabel(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get noDivesLoggedYet => 'Пока нет записей о погружениях';

  @override
  String get addDiveOrImportBody =>
      'Добавьте дайв вручную или импортируйте файл дневника.';

  @override
  String deleteDivesConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count дайва?',
      many: 'Удалить $count дайвов?',
      few: 'Удалить $count дайва?',
      one: 'Удалить $count дайв?',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteDivesError(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не удалось удалить $count дайва: $error',
      many: 'Не удалось удалить $count дайвов: $error',
      few: 'Не удалось удалить $count дайва: $error',
      one: 'Не удалось удалить $count дайв: $error',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteWithError(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get addADiveManually => 'Добавить дайв вручную';

  @override
  String get importADiveLogFile => 'Импортировать файл дневника';

  @override
  String get importFormatsSubtitle => 'UDDF, CSV или экспорт из Diving Log 6';

  @override
  String get csvColumnFormatTitle => 'Формат столбцов CSV';

  @override
  String get csvColumnFormatBody =>
      'Первая строка должна быть заголовком с этими названиями столбцов (в любом порядке, обязательна только \"date\"):\n\ndate (ГГГГ-ММ-ДД)\ntime (ЧЧ:ММ)\ncountry\nsite\nmax_depth_m\navg_depth_m\nduration_min\nmin_temp_c\nnotes';

  @override
  String get gotIt => 'Понятно';

  @override
  String diveImportedSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count дайва',
      many: 'Импортировано $count дайвов',
      few: 'Импортировано $count дайва',
      one: 'Импортирован $count дайв',
    );
    return '$_temp0';
  }

  @override
  String diveImportedWithSkipped(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count новых дайва, $skipped уже в дневнике',
      many: 'Импортировано $count новых дайвов, $skipped уже в дневнике',
      few: 'Импортировано $count новых дайва, $skipped уже в дневнике',
      one: 'Импортирован $count новый дайв, $skipped уже в дневнике',
    );
    return '$_temp0';
  }

  @override
  String couldNotImport(String error) {
    return 'Не удалось импортировать: $error';
  }

  @override
  String get unknownError => 'неизвестная ошибка';

  @override
  String get updateUnloggedCountPromptBody =>
      'Если часть из этого уже учтена в вашем профиле, обновите его в разделе Редактировать профиль.';

  @override
  String get editProfileAction => 'Редактировать профиль';

  @override
  String get depthLabel => 'Глубина';

  @override
  String get temperatureLabel => 'Температура';

  @override
  String get dragToInspectHint =>
      'Проведите по графику, чтобы посмотреть точку';

  @override
  String get done => 'Готово';

  @override
  String get searchLanguages => 'Поиск языков';

  @override
  String get languageSettingsTitle => 'Язык';

  @override
  String get systemDefault => 'Как в системе';

  @override
  String get guest => 'Гость';

  @override
  String get certificationsSectionTitle => 'Сертификации';

  @override
  String get update => 'Изменить';

  @override
  String get specialtiesSectionTitle => 'Специализации';

  @override
  String get gearSectionTitle => 'Снаряжение';

  @override
  String get couldNotUploadPhoto => 'Не удалось загрузить фото';

  @override
  String get couldNotRemovePhoto => 'Не удалось удалить фото';

  @override
  String get changePhoto => 'Изменить фото';

  @override
  String get removePhoto => 'Удалить фото';

  @override
  String get diveOut => 'Выйти';

  @override
  String get deleteAccountTitle => 'Удалить аккаунт?';

  @override
  String get deleteAccountBody =>
      'Это необратимо анонимизирует ваш аккаунт и отменит все организованные вами трипы. Это необратимо.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'Не удалось удалить аккаунт: $error';
  }

  @override
  String get deleteAccountRow => 'Удалить аккаунт';
}
