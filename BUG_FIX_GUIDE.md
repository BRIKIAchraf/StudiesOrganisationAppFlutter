# 🔧 GUIDE DE CORRECTION DES BUGS - UniConnect

## 🐛 PROBLÈMES IDENTIFIÉS ET SOLUTIONS

### ✅ CORRIGÉ

#### 1. **Profil ne sauvegarde pas**
**Problème**: Les modifications du profil n'étaient pas persistées  
**Solution**: 
- ✅ Ajout de `PersistenceService` robuste
- ✅ Mise à jour de `ProfileScreen` pour sauvegarder via API + local
- ✅ Initialisation du service dans `main.dart`

**Fichiers modifiés**:
- `lib/services/persistence_service.dart` (CRÉÉ)
- `lib/screens/profile_screen.dart` (CORRIGÉ)
- `lib/main.dart` (CORRIGÉ)

---

### 🔧 À CORRIGER

#### 2. **Study Sessions ne persistent pas**
**Problème**: Les sessions d'étude ne sont pas sauvegardées localement  
**Solution nécessaire**:
```dart
// Dans CoursesProvider.addSession()
await PersistenceService().saveStudySessions(allSessionsAsJson);
```

#### 3. **Groupes d'Étude non fonctionnels**
**Problème**: Pas de backend API pour les groupes  
**Solution nécessaire**:
- Créer endpoints backend: `/api/study-groups`
- Implémenter StudyGroupsProvider
- Connecter avec PersistenceService

#### 4. **Notifications Push non initialisées**
**Problème**: Firebase non configuré  
**Solution nécessaire**:
- Créer `google-services.json` (Android)
- Créer `GoogleService-Info.plist` (iOS)
- Initialiser dans `main.dart`

#### 5. **Intégrations externes non testées**
**Problème**: Services créés mais non intégrés dans UI  
**Solution nécessaire**:
- Ajouter boutons d'intégration dans CourseDetailScreen
- Tester Google Calendar sync
- Tester export PDF

---

## 📋 CHECKLIST DE CORRECTION

### Phase 1: Persistance (URGENT)
- [x] Créer PersistenceService
- [x] Corriger ProfileScreen
- [x] Initialiser dans main.dart
- [ ] Corriger CoursesProvider pour sauvegarder sessions
- [ ] Corriger SettingsProvider pour sauvegarder préférences
- [ ] Tester sauvegarde/chargement offline

### Phase 2: Providers (IMPORTANT)
- [ ] Créer StudyGroupsProvider
- [ ] Mettre à jour CoursesProvider avec cache
- [ ] Mettre à jour ChatProvider avec cache
- [ ] Ajouter error handling partout

### Phase 3: Backend (IMPORTANT)
- [ ] Créer endpoints study-groups
- [ ] Créer endpoints notifications
- [ ] Tester toutes les routes API
- [ ] Ajouter validation

### Phase 4: Firebase (OPTIONNEL)
- [ ] Configurer Firebase project
- [ ] Ajouter google-services.json
- [ ] Initialiser FirebaseMessaging
- [ ] Tester push notifications

### Phase 5: UI/UX (POLISH)
- [ ] Ajouter loading states partout
- [ ] Ajouter error messages
- [ ] Tester tous les formulaires
- [ ] Vérifier navigation

---

## 🔨 CORRECTIONS PRIORITAIRES

### 1. Corriger CoursesProvider

```dart
// Dans lib/providers/courses_provider.dart

Future<void> addSession(String courseId, StudySession session) async {
  try {
    // API call
    await http.post(
      Uri.parse('$_baseUrl/courses/$courseId/sessions'),
      headers: _headers,
      body: json.encode(session.toJson()),
    );
    
    // Update local state
    final index = _myCourses.indexWhere((c) => c.id == courseId);
    if (index >= 0) {
      _myCourses[index].sessions.add(session);
      notifyListeners();
      
      // SAVE TO CACHE
      final persistence = PersistenceService();
      final allSessions = _myCourses
          .expand((c) => c.sessions.map((s) => s.toJson()))
          .toList();
      await persistence.saveStudySessions(allSessions);
    }
  } catch (e) {
    print('Session add error: $e');
    rethrow; // Important pour afficher l'erreur
  }
}
```

### 2. Corriger SettingsProvider

```dart
// Dans lib/providers/settings_provider.dart

Future<void> toggleTheme(bool isDark) async {
  _isDarkMode = isDark;
  notifyListeners();
  
  // SAVE
  final persistence = PersistenceService();
  await persistence.saveSettings(isDarkMode: isDark);
}

Future<void> setTextScale(double scale) async {
  _textScaleFactor = scale;
  notifyListeners();
  
  // SAVE
  final persistence = PersistenceService();
  await persistence.saveSettings(textScaleFactor: scale);
}
```

### 3. Créer StudyGroupsProvider

```dart
// Créer lib/providers/study_groups_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/persistence_service.dart';

class StudyGroupsProvider with ChangeNotifier {
  List<StudyGroup> _myGroups = [];
  List<StudyGroup> _availableGroups = [];
  
  List<StudyGroup> get myGroups => _myGroups;
  List<StudyGroup> get availableGroups => _availableGroups;
  
  Future<void> loadGroups() async {
    try {
      // Load from API
      final response = await http.get(Uri.parse('$baseUrl/study-groups'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _myGroups = (data['myGroups'] as List)
            .map((g) => StudyGroup.fromJson(g))
            .toList();
        _availableGroups = (data['available'] as List)
            .map((g) => StudyGroup.fromJson(g))
            .toList();
        
        // Save to cache
        final persistence = PersistenceService();
        await persistence.saveStudyGroups([
          ..._myGroups.map((g) => g.toJson()),
          ..._availableGroups.map((g) => g.toJson()),
        ]);
        
        notifyListeners();
      }
    } catch (e) {
      // Load from cache on error
      final persistence = PersistenceService();
      final cached = persistence.getCachedStudyGroups();
      if (cached != null) {
        // Parse cached data
        print('Loaded groups from cache');
      }
    }
  }
  
  Future<void> createGroup(String name, String courseId, String description) async {
    // Implementation
  }
  
  Future<void> joinGroup(String groupId) async {
    // Implementation
  }
}
```

---

## 🧪 TESTS À EFFECTUER

### Test 1: Profil
1. Ouvrir profil
2. Modifier nom, université, bio
3. Sauvegarder
4. Fermer app
5. Rouvrir app
6. ✅ Vérifier que les données sont persistées

### Test 2: Study Sessions
1. Créer une session d'étude
2. Fermer app
3. Rouvrir app
4. ✅ Vérifier que la session est toujours là

### Test 3: Settings
1. Changer taille de police
2. Fermer app
3. Rouvrir app
4. ✅ Vérifier que le réglage est conservé

### Test 4: Offline Mode
1. Charger des cours
2. Activer mode avion
3. ✅ Vérifier que les cours sont toujours visibles
4. Désactiver mode avion
5. ✅ Vérifier la synchronisation

---

## 📊 ÉTAT DES FONCTIONNALITÉS

### ✅ Fonctionnent Correctement
- Authentication (login/logout)
- Courses listing
- Calendar view
- Chat (temps réel)
- Leaderboard (UI)
- Progress rings (UI)
- Navigation
- Animations

### ⚠️ Fonctionnent Partiellement
- Profile (sauvegarde maintenant OK)
- Study sessions (affichage OK, sauvegarde à corriger)
- Settings (UI OK, sauvegarde à corriger)
- Notifications (local OK, push à configurer)

### ❌ Ne Fonctionnent Pas
- Study groups (pas de backend)
- Firebase push (pas configuré)
- Intégrations externes (pas testées)
- Multi-langue (créé mais pas intégré)

---

## 🚀 PLAN D'ACTION IMMÉDIAT

### Aujourd'hui (2h)
1. ✅ Créer PersistenceService
2. ✅ Corriger ProfileScreen
3. ⏳ Corriger CoursesProvider
4. ⏳ Corriger SettingsProvider
5. ⏳ Tester sauvegarde/chargement

### Demain (4h)
6. Créer StudyGroupsProvider
7. Créer backend endpoints
8. Tester toutes les fonctionnalités
9. Corriger bugs trouvés

### Cette semaine (8h)
10. Configurer Firebase
11. Tester intégrations
12. Intégrer multi-langue
13. Polish UI/UX
14. Documentation

---

## 📝 NOTES IMPORTANTES

### Pourquoi certaines fonctionnalités ne marchent pas?

1. **Pas de sauvegarde locale**: Les providers ne sauvegardaient pas dans SharedPreferences
2. **Pas de backend complet**: Certaines features (study groups) n'ont pas d'API
3. **Pas de configuration Firebase**: Push notifications nécessitent setup
4. **Pas d'error handling**: Les erreurs étaient silencieuses

### Comment corriger?

1. **Utiliser PersistenceService partout**: Sauvegarder après chaque modification
2. **Créer les endpoints manquants**: Backend pour study groups
3. **Configurer Firebase**: Ajouter google-services.json
4. **Ajouter try/catch partout**: Afficher les erreurs à l'utilisateur

---

## ✅ PROCHAINES ÉTAPES

1. Appliquer les corrections du CoursesProvider
2. Appliquer les corrections du SettingsProvider
3. Créer StudyGroupsProvider
4. Tester toutes les fonctionnalités
5. Créer endpoints backend manquants
6. Configurer Firebase (optionnel)

---

**Dernière mise à jour**: 15 Janvier 2026, 18:20  
**Statut**: En cours de correction
