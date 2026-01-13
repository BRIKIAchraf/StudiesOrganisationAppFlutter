// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Planificateur d\'Études';

  @override
  String get welcomeBack => 'Bon Retour';

  @override
  String get createAccount => 'Créer un Compte';

  @override
  String get fullName => 'Nom Complet';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de Passe';

  @override
  String get login => 'CONNEXION';

  @override
  String get register => 'S\'INSCRIRE';

  @override
  String get newHere => 'Nouveau ici? S\'inscrire';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte? Se connecter';

  @override
  String get iAmA => 'Je suis un...';

  @override
  String get student => 'Étudiant';

  @override
  String get professor => 'Professeur';

  @override
  String get professorId => 'ID Professeur';

  @override
  String get professorIdHint => 'ex: PROF001';

  @override
  String get dashboard => 'Tableau de Bord';

  @override
  String get myCourses => 'Mes Cours';

  @override
  String get myTeaching => 'Mon Enseignement';

  @override
  String get studyHistory => 'Historique d\'Étude';

  @override
  String get courseStats => 'Statistiques de Cours';

  @override
  String get professorDashboard => 'Tableau de Bord Professeur';

  @override
  String get logout => 'Déconnexion';

  @override
  String get settings => 'Paramètres';

  @override
  String get appearance => 'Apparence';

  @override
  String get darkMode => 'Mode Sombre';

  @override
  String get profile => 'Profil';

  @override
  String get roleManagement => 'Gestion des Rôles';

  @override
  String get currentRole => 'Rôle Actuel';

  @override
  String get account => 'Compte';

  @override
  String get about => 'À Propos';

  @override
  String get version => 'Version';

  @override
  String get project => 'Projet';

  @override
  String get language => 'Langue';

  @override
  String get notifications => 'Notifications';

  @override
  String get welcomeNotification => 'Notification de Bienvenue';

  @override
  String get dailyReminders => 'Rappels Quotidiens d\'Étude';

  @override
  String get examAlerts => 'Alertes de Proximité d\'Examen';

  @override
  String get achievementNotifications => 'Notifications de Réussite';

  @override
  String get streakNotifications => 'Notifications de Série';

  @override
  String get addCourse => 'Ajouter un Cours';

  @override
  String get courseName => 'Nom du Cours';

  @override
  String get examDate => 'Date d\'Examen';

  @override
  String get noDateChosen => 'Aucune Date Choisie!';

  @override
  String get chooseDate => 'Choisir une Date';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get completed => 'Terminé';

  @override
  String get active => 'Actif';

  @override
  String get studyToday => 'ÉTUDE AUJOURD\'HUI';

  @override
  String get hours => 'Heures';

  @override
  String get weeklyActivity => 'Activité Hebdomadaire';

  @override
  String get upcomingExams => 'Examens à Venir';

  @override
  String get noCoursesYet => 'Pas encore de cours.';

  @override
  String get noMatchesFound => 'Aucun résultat trouvé.';

  @override
  String get searchCourses => 'Rechercher des cours...';

  @override
  String get sortByDate => 'Trier par date';

  @override
  String get newCourse => 'Nouveau Cours';

  @override
  String get deleteCourse => 'Supprimer le Cours?';

  @override
  String deleteConfirmation(Object courseName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$courseName\"? Toutes les sessions d\'étude seront perdues.';
  }

  @override
  String get courseCompleted => 'Cours terminé!';

  @override
  String get sessionUpdated => 'Session mise à jour!';

  @override
  String get sessionDeleted => 'Session supprimée';

  @override
  String get invalidDuration => 'Durée invalide';

  @override
  String get editSession => 'Modifier la Session';

  @override
  String get deleteSession => 'Supprimer la Session?';

  @override
  String get durationMinutes => 'Durée (minutes)';

  @override
  String get type => 'Type';

  @override
  String get stopwatch => 'Chronomètre';

  @override
  String get pomodoro => 'Pomodoro';

  @override
  String get notesOptional => 'Notes (optionnel)';

  @override
  String get activityHistory => 'Historique d\'Activité';

  @override
  String get noSessionsLogged => 'Aucune session enregistrée.';

  @override
  String get minutes => 'Minutes';

  @override
  String get quickThoughts => 'Notes Rapides';

  @override
  String get clickToAddNotes =>
      'Cliquez sur l\'icône de note ci-dessus pour ajouter des notes Markdown!';

  @override
  String get focusTimer => 'Minuteur de Concentration';

  @override
  String get focusing => 'CONCENTRATION';

  @override
  String get breakTime => 'PAUSE';

  @override
  String get sessionTooShort => 'Session trop courte!';

  @override
  String loggedMinutes(Object minutes) {
    return '$minutes minutes enregistrées!';
  }

  @override
  String get smartRecommendation => 'Recommandation Intelligente';

  @override
  String studyNext(Object courseName) {
    return 'Étudier $courseName Ensuite';
  }

  @override
  String get priorityHigh =>
      'Priorité: Haute (Examen proche ou peu d\'efforts)';

  @override
  String get start => 'COMMENCER';

  @override
  String get academicAchievements => 'Réussites Académiques';

  @override
  String get totalStudents => 'Total Étudiants';

  @override
  String get teachingLoad => 'Charge d\'Enseignement';

  @override
  String get campusGpa => 'GPA du Campus';

  @override
  String get completions => 'Achèvements';

  @override
  String get managementTools => 'Outils de Gestion';

  @override
  String get broadcastTip => 'Diffuser un Conseil d\'Étude';

  @override
  String get notifyStudents => 'Notifier tous les étudiants inscrits';

  @override
  String get gradeDistributions => 'Distributions de Notes';

  @override
  String get viewPerformance => 'Voir les tendances de performance globales';

  @override
  String get courseContent => 'Contenu du Cours';

  @override
  String get manageLectures => 'Gérer les cours et le matériel';
}
