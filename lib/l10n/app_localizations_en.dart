// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Study Planner';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get createAccount => 'Create Account';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'LOGIN';

  @override
  String get register => 'REGISTER';

  @override
  String get newHere => 'New here? Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get iAmA => 'I am a...';

  @override
  String get student => 'Student';

  @override
  String get professor => 'Professor';

  @override
  String get professorId => 'Professor ID';

  @override
  String get professorIdHint => 'e.g., PROF001';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get myCourses => 'My Courses';

  @override
  String get myTeaching => 'My Teaching';

  @override
  String get studyHistory => 'Study History';

  @override
  String get courseStats => 'Course Stats';

  @override
  String get professorDashboard => 'Professor Dashboard';

  @override
  String get logout => 'Log Out';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get profile => 'Profile';

  @override
  String get roleManagement => 'Role Management';

  @override
  String get currentRole => 'Current Role';

  @override
  String get account => 'Account';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get project => 'Project';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get welcomeNotification => 'Welcome Notification';

  @override
  String get dailyReminders => 'Daily Study Reminders';

  @override
  String get examAlerts => 'Exam Proximity Alerts';

  @override
  String get achievementNotifications => 'Achievement Notifications';

  @override
  String get streakNotifications => 'Streak Notifications';

  @override
  String get addCourse => 'Add Course';

  @override
  String get courseName => 'Course Name';

  @override
  String get examDate => 'Exam Date';

  @override
  String get noDateChosen => 'No Date Chosen!';

  @override
  String get chooseDate => 'Choose Date';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get completed => 'Completed';

  @override
  String get active => 'Active';

  @override
  String get studyToday => 'STUDY TODAY';

  @override
  String get hours => 'Hours';

  @override
  String get weeklyActivity => 'Weekly Activity';

  @override
  String get upcomingExams => 'Upcoming Exams';

  @override
  String get noCoursesYet => 'No courses yet.';

  @override
  String get noMatchesFound => 'No matches found.';

  @override
  String get searchCourses => 'Search courses...';

  @override
  String get sortByDate => 'Sort by date';

  @override
  String get newCourse => 'New Course';

  @override
  String get deleteCourse => 'Delete Course?';

  @override
  String deleteConfirmation(Object courseName) {
    return 'Are you sure you want to remove \"$courseName\"? All study sessions will be lost.';
  }

  @override
  String get courseCompleted => 'Course completed!';

  @override
  String get sessionUpdated => 'Session updated!';

  @override
  String get sessionDeleted => 'Session deleted';

  @override
  String get invalidDuration => 'Invalid duration';

  @override
  String get editSession => 'Edit Session';

  @override
  String get deleteSession => 'Delete Session?';

  @override
  String get durationMinutes => 'Duration (minutes)';

  @override
  String get type => 'Type';

  @override
  String get stopwatch => 'Stopwatch';

  @override
  String get pomodoro => 'Pomodoro';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get activityHistory => 'Activity History';

  @override
  String get noSessionsLogged => 'No sessions logged yet.';

  @override
  String get minutes => 'Minutes';

  @override
  String get quickThoughts => 'Quick Thoughts';

  @override
  String get clickToAddNotes =>
      'Click the note icon above to add Markdown notes!';

  @override
  String get focusTimer => 'Focus Timer';

  @override
  String get focusing => 'FOCUSING';

  @override
  String get breakTime => 'BREAK TIME';

  @override
  String get sessionTooShort => 'Session too short!';

  @override
  String loggedMinutes(Object minutes) {
    return 'Logged $minutes minutes!';
  }

  @override
  String get smartRecommendation => 'Smart Recommendation';

  @override
  String studyNext(Object courseName) {
    return 'Study $courseName Next';
  }

  @override
  String get priorityHigh => 'Priority: High (Nearest exam or low efforts)';

  @override
  String get start => 'START';

  @override
  String get academicAchievements => 'Academic Achievements';

  @override
  String get totalStudents => 'Total Students';

  @override
  String get teachingLoad => 'Teaching Load';

  @override
  String get campusGpa => 'Campus GPA';

  @override
  String get completions => 'Completions';

  @override
  String get managementTools => 'Management Tools';

  @override
  String get broadcastTip => 'Broadcast Study Tip';

  @override
  String get notifyStudents => 'Notify all enrolled students';

  @override
  String get gradeDistributions => 'Grade Distributions';

  @override
  String get viewPerformance => 'View global performance trends';

  @override
  String get courseContent => 'Course Content';

  @override
  String get manageLectures => 'Manage lectures and materials';
}
