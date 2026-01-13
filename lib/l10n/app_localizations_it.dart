// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Pianificatore di Studio';

  @override
  String get welcomeBack => 'Bentornato';

  @override
  String get createAccount => 'Crea Account';

  @override
  String get fullName => 'Nome Completo';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'ACCEDI';

  @override
  String get register => 'REGISTRATI';

  @override
  String get newHere => 'Nuovo qui? Registrati';

  @override
  String get alreadyHaveAccount => 'Hai già un account? Accedi';

  @override
  String get iAmA => 'Sono un...';

  @override
  String get student => 'Studente';

  @override
  String get professor => 'Professore';

  @override
  String get professorId => 'ID Professore';

  @override
  String get professorIdHint => 'es: PROF001';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get myCourses => 'I Miei Corsi';

  @override
  String get myTeaching => 'Il Mio Insegnamento';

  @override
  String get studyHistory => 'Cronologia Studio';

  @override
  String get courseStats => 'Statistiche Corso';

  @override
  String get professorDashboard => 'Dashboard Professore';

  @override
  String get logout => 'Disconnetti';

  @override
  String get settings => 'Impostazioni';

  @override
  String get appearance => 'Aspetto';

  @override
  String get darkMode => 'Modalità Scura';

  @override
  String get profile => 'Profilo';

  @override
  String get roleManagement => 'Gestione Ruoli';

  @override
  String get currentRole => 'Ruolo Attuale';

  @override
  String get account => 'Account';

  @override
  String get about => 'Informazioni';

  @override
  String get version => 'Versione';

  @override
  String get project => 'Progetto';

  @override
  String get language => 'Lingua';

  @override
  String get notifications => 'Notifiche';

  @override
  String get welcomeNotification => 'Notifica di Benvenuto';

  @override
  String get dailyReminders => 'Promemoria Giornalieri di Studio';

  @override
  String get examAlerts => 'Avvisi Prossimità Esame';

  @override
  String get achievementNotifications => 'Notifiche Risultati';

  @override
  String get streakNotifications => 'Notifiche Serie';

  @override
  String get addCourse => 'Aggiungi Corso';

  @override
  String get courseName => 'Nome Corso';

  @override
  String get examDate => 'Data Esame';

  @override
  String get noDateChosen => 'Nessuna Data Scelta!';

  @override
  String get chooseDate => 'Scegli Data';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get edit => 'Modifica';

  @override
  String get completed => 'Completato';

  @override
  String get active => 'Attivo';

  @override
  String get studyToday => 'STUDIO OGGI';

  @override
  String get hours => 'Ore';

  @override
  String get weeklyActivity => 'Attività Settimanale';

  @override
  String get upcomingExams => 'Prossimi Esami';

  @override
  String get noCoursesYet => 'Nessun corso ancora.';

  @override
  String get noMatchesFound => 'Nessun risultato trovato.';

  @override
  String get searchCourses => 'Cerca corsi...';

  @override
  String get sortByDate => 'Ordina per data';

  @override
  String get newCourse => 'Nuovo Corso';

  @override
  String get deleteCourse => 'Eliminare Corso?';

  @override
  String deleteConfirmation(Object courseName) {
    return 'Sei sicuro di voler rimuovere \"$courseName\"? Tutte le sessioni di studio saranno perse.';
  }

  @override
  String get courseCompleted => 'Corso completato!';

  @override
  String get sessionUpdated => 'Sessione aggiornata!';

  @override
  String get sessionDeleted => 'Sessione eliminata';

  @override
  String get invalidDuration => 'Durata non valida';

  @override
  String get editSession => 'Modifica Sessione';

  @override
  String get deleteSession => 'Eliminare Sessione?';

  @override
  String get durationMinutes => 'Durata (minuti)';

  @override
  String get type => 'Tipo';

  @override
  String get stopwatch => 'Cronometro';

  @override
  String get pomodoro => 'Pomodoro';

  @override
  String get notesOptional => 'Note (opzionale)';

  @override
  String get activityHistory => 'Cronologia Attività';

  @override
  String get noSessionsLogged => 'Nessuna sessione registrata.';

  @override
  String get minutes => 'Minuti';

  @override
  String get quickThoughts => 'Note Rapide';

  @override
  String get clickToAddNotes =>
      'Clicca sull\'icona nota sopra per aggiungere note Markdown!';

  @override
  String get focusTimer => 'Timer di Concentrazione';

  @override
  String get focusing => 'CONCENTRAZIONE';

  @override
  String get breakTime => 'PAUSA';

  @override
  String get sessionTooShort => 'Sessione troppo breve!';

  @override
  String loggedMinutes(Object minutes) {
    return '$minutes minuti registrati!';
  }

  @override
  String get smartRecommendation => 'Raccomandazione Intelligente';

  @override
  String studyNext(Object courseName) {
    return 'Studia $courseName Prossimo';
  }

  @override
  String get priorityHigh => 'Priorità: Alta (Esame vicino o pochi sforzi)';

  @override
  String get start => 'INIZIA';

  @override
  String get academicAchievements => 'Risultati Accademici';

  @override
  String get totalStudents => 'Totale Studenti';

  @override
  String get teachingLoad => 'Carico Didattico';

  @override
  String get campusGpa => 'GPA del Campus';

  @override
  String get completions => 'Completamenti';

  @override
  String get managementTools => 'Strumenti di Gestione';

  @override
  String get broadcastTip => 'Trasmetti Consiglio di Studio';

  @override
  String get notifyStudents => 'Notifica tutti gli studenti iscritti';

  @override
  String get gradeDistributions => 'Distribuzioni Voti';

  @override
  String get viewPerformance => 'Visualizza tendenze prestazioni globali';

  @override
  String get courseContent => 'Contenuto Corso';

  @override
  String get manageLectures => 'Gestisci lezioni e materiali';
}
