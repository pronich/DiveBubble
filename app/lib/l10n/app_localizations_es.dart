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

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get you => 'Tú';

  @override
  String get diver => 'Buceador';

  @override
  String get searchBubbles => 'Buscar Bubbles';

  @override
  String get noMatches => 'Sin coincidencias.';

  @override
  String get share => 'Compartir';

  @override
  String get documentFallbackName => 'Documento.pdf';

  @override
  String get copiedToClipboard => 'Copiado';

  @override
  String get deleteThisMessageTitle => '¿Eliminar este mensaje?';

  @override
  String get deleteThisMessageBody =>
      'Esto no se puede deshacer: se eliminará para todos en este Bubble.';

  @override
  String couldNotDeleteMessage(String error) {
    return 'No se pudo eliminar el mensaje: $error';
  }

  @override
  String couldNotReact(String error) {
    return 'No se pudo reaccionar: $error';
  }

  @override
  String get reply => 'Responder';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get report => 'Reportar';

  @override
  String get removeDocumentFirst =>
      'Elimina primero el documento para añadir fotos.';

  @override
  String onlyNAttachmentsAllowed(int max) {
    return 'Solo se permiten $max archivos adjuntos por mensaje.';
  }

  @override
  String get documentOnlyOnItsOwn => 'Un documento solo se puede enviar solo.';

  @override
  String get someFilesTooLarge => 'Algunos archivos son demasiado grandes.';

  @override
  String couldNotSendAttachment(String error) {
    return 'No se pudo enviar el archivo adjunto: $error';
  }

  @override
  String get noMessagesYet => 'Aún no hay mensajes';

  @override
  String get tripCancelledReadOnly =>
      'Este viaje ha sido cancelado; el chat es de solo lectura.';

  @override
  String replyingTo(String name) {
    return 'Respondiendo a $name';
  }

  @override
  String get captionOptional => 'Descripción (opcional)';

  @override
  String get messageHint => 'Mensaje';

  @override
  String get messageDeleted => 'Mensaje eliminado';

  @override
  String attachmentsCountLabel(int count) {
    return '📎 $count archivos adjuntos';
  }

  @override
  String get photoLabel => '📷 Foto';

  @override
  String get videoLabel => '🎬 Vídeo';

  @override
  String get pdfLabel => '📄 PDF';

  @override
  String get newMessages => 'Nuevos mensajes';

  @override
  String get productObserver => 'Product Observer';

  @override
  String get reportMessageTitle => 'Reportar mensaje';

  @override
  String get detailsOptional => 'Detalles (opcional)';

  @override
  String get sendReport => 'Enviar reporte';

  @override
  String get reportSentThankYou => 'Reporte enviado, gracias.';

  @override
  String couldNotSendReport(String error) {
    return 'No se pudo enviar el reporte: $error';
  }

  @override
  String get thankYou => '¡Gracias!';

  @override
  String get giveFeedback => 'Dar tu opinión';

  @override
  String get howUsefulQuestion =>
      '¿Qué tan útil fue DiveBubble para este viaje?';

  @override
  String get whatDidHelpQuestion => '¿En qué te ayudó DiveBubble?';

  @override
  String get whatShouldImproveQuestion => '¿Qué deberíamos mejorar?';

  @override
  String get optionalHintText => 'Opcional';

  @override
  String get canContactAboutFeedback =>
      '¿Podemos contactarte sobre tu opinión?';

  @override
  String get submitFeedback => 'Enviar opinión';

  @override
  String couldNotSendFeedback(String error) {
    return 'No se pudo enviar la opinión: $error';
  }

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Acoso';

  @override
  String get reportReasonInappropriateContent => 'Contenido inapropiado';

  @override
  String get reportReasonOther => 'Otro';

  @override
  String get helpedWithTripInformation => 'Información del viaje';

  @override
  String get helpedWithChattingWithParticipants =>
      'Chatear con los participantes';

  @override
  String get helpedWithFindingTransport => 'Encontrar transporte';

  @override
  String get helpedWithFindingBuddy => 'Encontrar buddy';

  @override
  String get helpedWithNothingYet => 'Nada aún';

  @override
  String couldNotSharePhoto(String error) {
    return 'No se pudo compartir la foto: $error';
  }

  @override
  String couldNotShareVideo(String error) {
    return 'No se pudo compartir el vídeo: $error';
  }

  @override
  String get couldNotLoadVideo => 'No se pudo cargar el vídeo';

  @override
  String couldNotLoadMedia(String error) {
    return 'No se pudo cargar el contenido multimedia: $error';
  }

  @override
  String get noPhotosOrVideosSharedYet =>
      'Aún no se han compartido fotos ni vídeos';

  @override
  String couldNotLoadFiles(String error) {
    return 'No se pudieron cargar los archivos: $error';
  }

  @override
  String get noFilesSharedYet => 'Aún no se han compartido archivos';

  @override
  String couldNotLoadLinks(String error) {
    return 'No se pudieron cargar los enlaces: $error';
  }

  @override
  String get noLinksSharedYet => 'Aún no se han compartido enlaces';

  @override
  String get shareToABubble => 'Compartir en un Bubble';

  @override
  String get noBubblesYet => 'Aún no hay Bubbles';

  @override
  String get joinATripToShareInto =>
      'Únete a un viaje para tener un Bubble en el que compartir.';

  @override
  String get bubblesTabTitle => 'Bubbles';

  @override
  String get diveLogTabTitle => 'Bitácora';

  @override
  String get profileTabTitle => 'Perfil';

  @override
  String get signInToSeeYourTrips => 'Inicia sesión para ver tus viajes';

  @override
  String get logInToViewTripsBody =>
      'Inicia sesión para ver los viajes a los que te has unido y sus chats grupales.';

  @override
  String get startYourFirstBubble => 'Crea tu primer Bubble';

  @override
  String get startYourFirstBubbleBody =>
      'Crea un viaje o únete con un código: chat, transporte y detalles del viaje en un solo lugar.';

  @override
  String get createTrip => 'Crear viaje';

  @override
  String get joinTrip => 'Unirse';

  @override
  String get chatTabLabel => 'Chat';

  @override
  String get transportTabLabel => 'Transporte';

  @override
  String get buddyTabLabel => 'Buddy';

  @override
  String get expensesTabLabel => 'Gastos';

  @override
  String get archive => 'Archivar';

  @override
  String get unarchive => 'Desarchivar';

  @override
  String get cancelTrip => 'Cancelar viaje';

  @override
  String get leave => 'Salir';

  @override
  String couldNotArchive(String error) {
    return 'No se pudo archivar: $error';
  }

  @override
  String couldNotUnarchive(String error) {
    return 'No se pudo desarchivar: $error';
  }

  @override
  String get leaveBubbleTitle => '¿Salir de este Bubble?';

  @override
  String get leaveBubbleBody =>
      'Perderás tu plaza y podrás volver a unirte más adelante si hay sitio.';

  @override
  String couldNotLeave(String error) {
    return 'No se pudo salir: $error';
  }

  @override
  String get cancelTripTitle => '¿Cancelar este viaje?';

  @override
  String get cancelTripBody =>
      'Todos los participantes conservan el Bubble para ver el historial del chat, pero nadie, ni siquiera tú, podrá enviar mensajes, unirse ni organizar transporte. Esto no se puede deshacer.';

  @override
  String get neverMind => 'No, gracias';

  @override
  String couldNotCancel(String error) {
    return 'No se pudo cancelar: $error';
  }

  @override
  String get cancelledStatus => 'Cancelado';

  @override
  String get pastStatus => 'Pasado';

  @override
  String get activeStatus => 'Activo';

  @override
  String get archivedChats => 'Chats archivados';

  @override
  String get noArchivedChats => 'No hay chats archivados';

  @override
  String get archivedChatsEmptyBody =>
      'Los Bubbles que archives aparecerán aquí; desliza o desarchívalos para recuperarlos.';

  @override
  String get typeOfferRide => 'Ofrezco un viaje en coche';

  @override
  String get typeShareRental => 'Comparto un alquiler';

  @override
  String get carCancelledByOrganizer =>
      'Este coche fue cancelado por el organizador.';

  @override
  String get noTransportWasArranged => 'No se organizó transporte';

  @override
  String get beFirstToShareTransport => 'Sé el primero en compartir transporte';

  @override
  String get tripCancelledSimple => 'Este viaje ha sido cancelado.';

  @override
  String get offerRideOrShareRental =>
      'Ofrece un viaje en coche o comparte un alquiler para que otros se unan.';

  @override
  String get addTransportInfo => 'Añadir transporte';

  @override
  String seatsTakenLabel(int joined, int total) {
    return '$joined de $total plazas ocupadas';
  }

  @override
  String get joinedStatus => 'Unido';

  @override
  String get fullStatus => 'Completo';

  @override
  String get organizerLabel => 'Organizador';

  @override
  String get organizerYou => 'Organizador · Tú';

  @override
  String get joinedDivers => 'Buceadores unidos';

  @override
  String get noOneHasJoinedYet => 'Nadie se ha unido aún';

  @override
  String get cancelCarOffer => 'Cancelar coche';

  @override
  String get leaveCar => 'Salir del coche';

  @override
  String get join => 'Unirse';

  @override
  String get seatsOptional => 'Plazas (opcional)';

  @override
  String get detailsTimePickupOptional =>
      'Detalles: hora, punto de recogida (opcional)';

  @override
  String get add => 'Añadir';

  @override
  String get buddyGroupCancelledByOrganizer =>
      'Este grupo de buddy fue cancelado por el organizador.';

  @override
  String get noBuddyRequestsWereMade => 'No se hicieron solicitudes de buddy';

  @override
  String get beFirstToLookForBuddy => 'Sé el primero en buscar un buddy';

  @override
  String get requestBuddySoOthersCanJoin =>
      'Solicita un buddy para que otros puedan unirse a ti en esta inmersión.';

  @override
  String get requestABuddy => 'Buscar buddy';

  @override
  String get buddyRequestTitle => 'Solicitud de buddy';

  @override
  String divesCountLabel(int count) {
    return '$count inmersiones';
  }

  @override
  String get creatorLabel => 'Creador';

  @override
  String get creatorYou => 'Creador · Tú';

  @override
  String get groupLabel => 'Grupo';

  @override
  String get cancelBuddyRequest => 'Cancelar solicitud';

  @override
  String get leaveBuddyGroup => 'Salir del grupo';

  @override
  String get otherDiversWillSeeRequest =>
      'Otros buceadores de este viaje verán tu solicitud y podrán unirse.';

  @override
  String get request => 'Enviar';

  @override
  String get about => 'Acerca de';

  @override
  String versionLabel(String version) {
    return 'Versión $version';
  }

  @override
  String get gearLockerTitle => 'Equipo';

  @override
  String ownedOfTotalInLocker(int owned, int total) {
    return '$owned/$total en el equipo';
  }

  @override
  String get clearCacheTitle => '¿Borrar caché?';

  @override
  String get clearCacheBody =>
      'Esto elimina las fotos y archivos descargados de este dispositivo. No se elimina nada de los chats de viaje: los archivos simplemente se volverán a descargar la próxima vez que los abras.';

  @override
  String get clear => 'Borrar';

  @override
  String get cacheCleared => 'Caché borrada.';

  @override
  String couldNotClearCache(String error) {
    return 'No se pudo borrar la caché: $error';
  }

  @override
  String get storageTitle => 'Almacenamiento';

  @override
  String get clearCacheRow => 'Borrar caché';

  @override
  String get clearCacheSubtitle =>
      'Elimina las fotos y archivos de chat descargados de este dispositivo';

  @override
  String couldNotUnblock(String error) {
    return 'No se pudo desbloquear: $error';
  }

  @override
  String get blockedUsersTitle => 'Usuarios bloqueados';

  @override
  String get noBlockedUsers => 'No hay usuarios bloqueados.';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get copyEmailAddress => 'Copiar dirección de correo';

  @override
  String get emailAddressCopied => 'Dirección de correo copiada';

  @override
  String get legalTitle => 'Legal';

  @override
  String get termsOfService => 'Términos del servicio';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get contactSupport => 'Contactar con soporte';

  @override
  String get addADive => 'Añadir inmersión';

  @override
  String get updateLevelTitle => 'Actualizar nivel';

  @override
  String get save => 'Guardar';

  @override
  String get addSpeciality => 'Añadir especialidad';

  @override
  String get specialityName => 'Nombre de la especialidad';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get pushNotificationsLabel => 'Notificaciones push';

  @override
  String get pushDisabledInSystemSettings =>
      'Desactivadas en los ajustes del sistema; activa antes las notificaciones de DiveBubble allí';

  @override
  String get tapToEnableNotifications => 'Toca para activar las notificaciones';

  @override
  String get newMessagesTripUpdatesEtc =>
      'Nuevos mensajes, cambios en los viajes y más';

  @override
  String get verified => 'Verificado';

  @override
  String get addCertificate => 'Añadir certificado';

  @override
  String get blockThisUserTitle => '¿Bloquear a este usuario?';

  @override
  String get blockUserBody =>
      'Ya no verás sus mensajes en los chats de viaje compartidos. Puedes deshacer esto desde Perfil → Usuarios bloqueados.';

  @override
  String get block => 'Bloquear';

  @override
  String get blockUserTooltip => 'Bloquear usuario';

  @override
  String get blockedManageBody =>
      'Bloqueado. Gestiónalo en Perfil → Usuarios bloqueados.';

  @override
  String couldNotBlockUser(String error) {
    return 'No se pudo bloquear al usuario: $error';
  }

  @override
  String get bioLabel => 'Biografía';

  @override
  String get divesLabel => 'Inmersiones';

  @override
  String get languagesLabel => 'Idiomas';

  @override
  String get memberSinceLabel => 'Miembro desde';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get displayNameLabel => 'Nombre visible';

  @override
  String get displayNameHelper =>
      'Se muestra a otros buceadores en lugar de tu nombre real';

  @override
  String get pleaseEnterDisplayName => 'Introduce un nombre visible';

  @override
  String get locationLabel => 'Ubicación';

  @override
  String get useCurrentLocationTooltip => 'Usar ubicación actual';

  @override
  String get unloggedDivesLabel => 'Inmersiones sin registrar';

  @override
  String get unloggedDivesHelper =>
      'Inmersiones que no has añadido a tu bitácora — se muestran junto a ella en tu total';

  @override
  String get allDivesAreLogged => 'Todas mis inmersiones están registradas';

  @override
  String get selectLanguages => 'Selecciona idiomas';

  @override
  String get zeroOutUnloggedDivesTitle =>
      '¿Poner a cero las inmersiones sin registrar?';

  @override
  String get zeroOutUnloggedDivesBody =>
      'Esto pone a 0 el número de arriba. Tus entradas de la bitácora no se ven afectadas — solo cambia el número introducido manualmente.';

  @override
  String get zeroOut => 'Poner a cero';

  @override
  String get editDiveTitle => 'Editar inmersión';

  @override
  String get addDiveTitle => 'Añadir inmersión';

  @override
  String get importedDiveLockedNotice =>
      'Esta inmersión se importó desde tu ordenador de buceo — solo se pueden editar el país, el punto de inmersión y las notas.';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get timeLabel => 'Hora';

  @override
  String get maxDepthLabel => 'Profundidad máx.';

  @override
  String get avgDepthLabel => 'Profundidad media';

  @override
  String get durationLabel => 'Duración';

  @override
  String get minTemperatureLabel => 'Temperatura mín.';

  @override
  String get minTempLabel => 'Temp. mín.';

  @override
  String get maxTempLabel => 'Temp. máx.';

  @override
  String get countryLabel => 'País';

  @override
  String get diveSiteLabel => 'Punto de inmersión';

  @override
  String get notesLabel => 'Notas';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get deleteThisDiveTitle => '¿Eliminar esta inmersión?';

  @override
  String get cantBeUndone => 'Esto no se puede deshacer.';

  @override
  String get gearEssentialSection => 'ESENCIAL';

  @override
  String get gearAdditionalSection => 'ADICIONAL';

  @override
  String get addItem => 'Añadir artículo';

  @override
  String get gearOwned => 'Tengo';

  @override
  String get gearMissing => 'Falta';

  @override
  String get gearUsuallyRent => 'Suelo alquilar';

  @override
  String get addItemSheetBody =>
      'Para cualquier cosa más allá de lo esencial: linterna, cámara de acción, boya...';

  @override
  String get itemNameLabel => 'Nombre del artículo';

  @override
  String get gearItemBoots => 'Botas';

  @override
  String get gearItemFins => 'Aletas';

  @override
  String get gearItemBcd => 'BCD';

  @override
  String get gearItemWetsuitShorty5mm => 'Traje shorty 5mm';

  @override
  String get gearItemWetsuit5mm => 'Traje de neopreno 5mm';

  @override
  String get gearItemWetsuit7mm => 'Traje de neopreno 7mm';

  @override
  String get gearItemWetsuit9mm => 'Traje de neopreno 9mm';

  @override
  String get gearItemSemidrySuit => 'Traje semiseco';

  @override
  String get gearItemDrySuit => 'Traje seco';

  @override
  String get gearItemHelmet => 'Casco';

  @override
  String get gearItemGloves => 'Guantes';

  @override
  String get gearItemRegulator => 'Regulador';

  @override
  String get gearItemComputer => 'Ordenador de buceo';

  @override
  String get gearItemMask => 'Máscara';

  @override
  String get shareToBubble => 'Compartir en Bubble';

  @override
  String get sourceLabel => 'Origen';

  @override
  String get importedValue => 'Importado';

  @override
  String get manualValue => 'Manual';

  @override
  String diveOnDate(String date) {
    return 'Inmersión el $date';
  }

  @override
  String labelColonValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get sharedToBubble => 'Compartido en Bubble';

  @override
  String couldNotShare(String error) {
    return 'No se pudo compartir: $error';
  }

  @override
  String get haventJoinedAnyBubblesYet =>
      'Aún no te has unido a ningún Bubble.';

  @override
  String selectedCountLabel(int count) {
    return '$count seleccionadas';
  }

  @override
  String get noDivesLoggedYet => 'Aún no hay inmersiones registradas';

  @override
  String get addDiveOrImportBody =>
      'Añade una inmersión a mano o importa un archivo de bitácora.';

  @override
  String deleteDivesConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count inmersiones?',
      one: '¿Eliminar $count inmersión?',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteDivesError(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No se pudieron eliminar $count inmersiones: $error',
      one: 'No se pudo eliminar $count inmersión: $error',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteWithError(String error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String get addADiveManually => 'Añadir una inmersión manualmente';

  @override
  String get importADiveLogFile => 'Importar un archivo de bitácora';

  @override
  String get importFormatsSubtitle =>
      'UDDF, CSV o una exportación de Diving Log 6';

  @override
  String get csvColumnFormatTitle => 'Formato de columnas CSV';

  @override
  String get csvColumnFormatBody =>
      'La primera fila debe ser un encabezado con estos nombres de columna (en cualquier orden, solo \"date\" es obligatoria):\n\ndate (AAAA-MM-DD)\ntime (HH:MM)\ncountry\nsite\nmax_depth_m\navg_depth_m\nduration_min\nmin_temp_c\nnotes';

  @override
  String get gotIt => 'Entendido';

  @override
  String diveImportedSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inmersiones importadas',
      one: '$count inmersión importada',
    );
    return '$_temp0';
  }

  @override
  String diveImportedWithSkipped(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inmersiones nuevas importadas, $skipped ya registradas',
      one: '$count inmersión nueva importada, $skipped ya registrada',
    );
    return '$_temp0';
  }

  @override
  String couldNotImport(String error) {
    return 'No se pudo importar: $error';
  }

  @override
  String get unknownError => 'error desconocido';

  @override
  String get updateUnloggedCountPromptBody =>
      'Si alguna de estas ya estaba contada en tu perfil, actualízalo en Editar perfil.';

  @override
  String get editProfileAction => 'Editar perfil';

  @override
  String get depthLabel => 'Profundidad';

  @override
  String get temperatureLabel => 'Temperatura';

  @override
  String get dragToInspectHint =>
      'Arrastra por el gráfico para inspeccionar un punto';

  @override
  String get done => 'Listo';

  @override
  String get searchLanguages => 'Buscar idiomas';

  @override
  String get languageSettingsTitle => 'Idioma';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get guest => 'Invitado';

  @override
  String get certificationsSectionTitle => 'Certificaciones';

  @override
  String get update => 'Actualizar';

  @override
  String get specialtiesSectionTitle => 'Especialidades';

  @override
  String get gearSectionTitle => 'Equipo';

  @override
  String get couldNotUploadPhoto => 'No se pudo subir la foto';

  @override
  String get couldNotRemovePhoto => 'No se pudo eliminar la foto';

  @override
  String get changePhoto => 'Cambiar foto';

  @override
  String get removePhoto => 'Eliminar foto';

  @override
  String get diveOut => 'Salir';

  @override
  String get deleteAccountTitle => '¿Eliminar cuenta?';

  @override
  String get deleteAccountBody =>
      'Esto anonimiza tu cuenta de forma permanente y cancela cualquier viaje que organices. Esto no se puede deshacer.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'No se pudo eliminar la cuenta: $error';
  }

  @override
  String get deleteAccountRow => 'Eliminar cuenta';

  @override
  String get noExpensesYet => 'Aún no hay gastos';

  @override
  String get logSharedCostBody =>
      'Registra un gasto compartido para que todos sepan cuánto deben.';

  @override
  String get addExpenseCta => 'Añadir gasto';

  @override
  String get addExpenseTitle => 'Añadir gasto';

  @override
  String get editExpenseTitle => 'Editar gasto';

  @override
  String get allSettledUp => 'Todo saldado';

  @override
  String get allSettledUpPeriod => 'Todo saldado.';

  @override
  String youAreOwedAmount(String amount) {
    return 'Te deben $amount';
  }

  @override
  String youOweAmount(String amount) {
    return 'Debes $amount';
  }

  @override
  String youOweName(String name) {
    return 'Le debes a $name';
  }

  @override
  String nameOwesYou(String name) {
    return '$name te debe';
  }

  @override
  String paidByAndDate(String name, String date) {
    return 'Pagado por $name · $date';
  }

  @override
  String get balanceTitle => 'Balance';

  @override
  String get markSettled => 'Marcar como pagado';

  @override
  String couldNotSettle(String error) {
    return 'No se pudo saldar: $error';
  }

  @override
  String get titleFieldLabel => 'Título';

  @override
  String get amountLabel => 'Importe';

  @override
  String get paidByLabel => 'Pagado por';

  @override
  String get splitEqual => 'Igual';

  @override
  String get splitShares => 'Partes';

  @override
  String get splitExact => 'Exacto';

  @override
  String get splitBetweenLabel => 'Dividir entre';

  @override
  String get fullyAssigned => 'Completamente asignado';

  @override
  String remainingToAssign(String amount) {
    return 'Pendiente de asignar: $amount';
  }

  @override
  String get fillTitleAmountParticipant =>
      'Indica un título, un importe y al menos un participante.';

  @override
  String get enterExactAmountForEveryone =>
      'Introduce un importe exacto para cada seleccionado.';

  @override
  String get exactAmountsMustAddUp =>
      'Los importes exactos deben sumar el total.';

  @override
  String get deleteExpenseTitle => '¿Eliminar este gasto?';

  @override
  String get deleteExpenseBody =>
      'Se eliminará del balance para todos. Esto no se puede deshacer.';
}
