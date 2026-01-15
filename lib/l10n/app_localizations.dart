import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'home': 'Home',
      'courses': 'Courses',
      'calendar': 'Calendar',
      'settings': 'Settings',
      'profile': 'Profile',
      'leaderboard': 'Leaderboard',
      'study_groups': 'Study Groups',
      
      // Home Screen
      'welcome_back': 'Welcome back',
      'study_time_today': 'Study Time Today',
      'minutes': 'minutes',
      'recommended_course': 'Recommended Course',
      'upcoming_exams': 'Upcoming Exams',
      'achievements': 'Achievements',
      'daily_tip': 'Daily Tip',
      
      // Courses
      'my_courses': 'My Courses',
      'find_courses': 'Find Courses',
      'search_courses': 'Search courses...',
      'filter': 'Filter',
      'sort_by_date': 'Sort by Date',
      'pending': 'Pending',
      'approved': 'Approved',
      'rejected': 'Rejected',
      
      // Calendar
      'exam_calendar': 'Exam Calendar',
      'set_reminder': 'Set Reminder',
      'one_hour_before': '1 Hour Before',
      'one_day_before': '24 Hours Before',
      
      // Chat
      'type_message': 'Type a message...',
      'send': 'Send',
      'attach_file': 'Attach File',
      'search': 'Search',
      
      // Profile
      'edit_profile': 'Edit Profile',
      'full_name': 'Full Name',
      'university': 'University',
      'department': 'Department',
      'bio': 'Bio',
      'save_changes': 'Save Changes',
      'logout': 'Logout',
      
      // Leaderboard
      'study_time': 'Study Time',
      'grades': 'Grades',
      'streaks': 'Streaks',
      'days': 'days',
      'avg': 'avg',
      
      // Study Groups
      'create_group': 'Create Group',
      'join_group': 'Join',
      'group_name': 'Group Name',
      'description': 'Description',
      'members': 'members',
      
      // Common
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'create': 'Create',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'confirm': 'Confirm',
    },
    'fr': {
      // Navigation
      'home': 'Accueil',
      'courses': 'Cours',
      'calendar': 'Calendrier',
      'settings': 'Paramètres',
      'profile': 'Profil',
      'leaderboard': 'Classement',
      'study_groups': 'Groupes d\'Étude',
      
      // Home Screen
      'welcome_back': 'Bon retour',
      'study_time_today': 'Temps d\'Étude Aujourd\'hui',
      'minutes': 'minutes',
      'recommended_course': 'Cours Recommandé',
      'upcoming_exams': 'Examens à Venir',
      'achievements': 'Réalisations',
      'daily_tip': 'Conseil du Jour',
      
      // Courses
      'my_courses': 'Mes Cours',
      'find_courses': 'Trouver des Cours',
      'search_courses': 'Rechercher des cours...',
      'filter': 'Filtrer',
      'sort_by_date': 'Trier par Date',
      'pending': 'En Attente',
      'approved': 'Approuvé',
      'rejected': 'Rejeté',
      
      // Calendar
      'exam_calendar': 'Calendrier des Examens',
      'set_reminder': 'Définir un Rappel',
      'one_hour_before': '1 Heure Avant',
      'one_day_before': '24 Heures Avant',
      
      // Chat
      'type_message': 'Tapez un message...',
      'send': 'Envoyer',
      'attach_file': 'Joindre un Fichier',
      'search': 'Rechercher',
      
      // Profile
      'edit_profile': 'Modifier le Profil',
      'full_name': 'Nom Complet',
      'university': 'Université',
      'department': 'Département',
      'bio': 'Biographie',
      'save_changes': 'Enregistrer les Modifications',
      'logout': 'Déconnexion',
      
      // Leaderboard
      'study_time': 'Temps d\'Étude',
      'grades': 'Notes',
      'streaks': 'Séries',
      'days': 'jours',
      'avg': 'moy',
      
      // Study Groups
      'create_group': 'Créer un Groupe',
      'join_group': 'Rejoindre',
      'group_name': 'Nom du Groupe',
      'description': 'Description',
      'members': 'membres',
      
      // Common
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'create': 'Créer',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'confirm': 'Confirmer',
    },
    'ar': {
      // Navigation
      'home': 'الرئيسية',
      'courses': 'الدورات',
      'calendar': 'التقويم',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'leaderboard': 'لوحة المتصدرين',
      'study_groups': 'مجموعات الدراسة',
      
      // Home Screen
      'welcome_back': 'مرحبا بعودتك',
      'study_time_today': 'وقت الدراسة اليوم',
      'minutes': 'دقائق',
      'recommended_course': 'الدورة الموصى بها',
      'upcoming_exams': 'الامتحانات القادمة',
      'achievements': 'الإنجازات',
      'daily_tip': 'نصيحة اليوم',
      
      // Courses
      'my_courses': 'دوراتي',
      'find_courses': 'البحث عن دورات',
      'search_courses': 'البحث عن دورات...',
      'filter': 'تصفية',
      'sort_by_date': 'ترتيب حسب التاريخ',
      'pending': 'قيد الانتظار',
      'approved': 'موافق عليه',
      'rejected': 'مرفوض',
      
      // Calendar
      'exam_calendar': 'تقويم الامتحانات',
      'set_reminder': 'تعيين تذكير',
      'one_hour_before': 'قبل ساعة واحدة',
      'one_day_before': 'قبل 24 ساعة',
      
      // Chat
      'type_message': 'اكتب رسالة...',
      'send': 'إرسال',
      'attach_file': 'إرفاق ملف',
      'search': 'بحث',
      
      // Profile
      'edit_profile': 'تعديل الملف الشخصي',
      'full_name': 'الاسم الكامل',
      'university': 'الجامعة',
      'department': 'القسم',
      'bio': 'السيرة الذاتية',
      'save_changes': 'حفظ التغييرات',
      'logout': 'تسجيل الخروج',
      
      // Leaderboard
      'study_time': 'وقت الدراسة',
      'grades': 'الدرجات',
      'streaks': 'السلاسل',
      'days': 'أيام',
      'avg': 'متوسط',
      
      // Study Groups
      'create_group': 'إنشاء مجموعة',
      'join_group': 'انضمام',
      'group_name': 'اسم المجموعة',
      'description': 'الوصف',
      'members': 'أعضاء',
      
      // Common
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'create': 'إنشاء',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجاح',
      'confirm': 'تأكيد',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Helper getters
  String get home => translate('home');
  String get courses => translate('courses');
  String get calendar => translate('calendar');
  String get settings => translate('settings');
  String get profile => translate('profile');
  String get leaderboard => translate('leaderboard');
  String get studyGroups => translate('study_groups');
  
  String get welcomeBack => translate('welcome_back');
  String get studyTimeToday => translate('study_time_today');
  String get minutes => translate('minutes');
  
  String get myCourses => translate('my_courses');
  String get findCourses => translate('find_courses');
  String get searchCourses => translate('search_courses');
  
  String get typeMessage => translate('type_message');
  String get send => translate('send');
  
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get loading => translate('loading');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
