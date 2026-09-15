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
}
