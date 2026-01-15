# 🔄 Architecture et Flux de l'Application UniConnect

## 📊 DIAGRAMME DE LIAISON PROFESSEUR ↔ ÉTUDIANT

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FLUX D'INSCRIPTION À UN COURS                         │
└─────────────────────────────────────────────────────────────────────────┘

    👨‍🏫 PROFESSEUR                                        🎓 ÉTUDIANT
    ─────────────                                        ──────────
         │                                                    │
         │ 1. Crée un cours                                  │
         │    - Titre                                        │
         │    - Description                                  │
         │    - Date d'examen                                │
         ▼                                                    │
    ┌─────────┐                                              │
    │  COURS  │◄─────────────────────────────────────────────┤
    │ Créé ✅ │                                              │
    └────┬────┘              2. Découvre le cours            │
         │                      dans "All Courses"           │
         │                                                    │
         │                                                    ▼
         │                                           ┌────────────────┐
         │                                           │ Demande Accès  │
         │                                           │   (Enroll)     │
         │                                           └────────┬───────┘
         │                                                    │
         │                  3. Enrollment Request             │
         │◄───────────────────────────────────────────────────┤
         │                  Status: PENDING 🟡                │
         ▼                                                    │
    ┌──────────────────┐                                     │
    │ Reçoit demande   │                                     │
    │ dans Dashboard   │                                     │
    └────┬─────────────┘                                     │
         │                                                    │
         │ 4. Décision                                       │
         ├──────────┬──────────┐                            │
         │          │          │                             │
    APPROUVER   REJETER    IGNORER                          │
         │          │          │                             │
         ▼          ▼          ▼                             │
    ┌────────┐ ┌────────┐ ┌────────┐                       │
    │ Status │ │ Status │ │ Status │                       │
    │APPROVED│ │REJECTED│ │PENDING │                       │
    │   ✅   │ │   ❌   │ │   ⏳   │                       │
    └────┬───┘ └────┬───┘ └────┬───┘                       │
         │          │          │                             │
         │          │          └─────────────────────────────┤
         │          │                                        │
         │          └────────────────────────────────────────┤
         │                   Accès Refusé ❌                 │
         │                                                    │
         └────────────────────────────────────────────────────┤
                            Accès Accordé ✅                 │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │  ACCÈS COMPLET   │
                                                    ├──────────────────┤
                                                    │ 📚 Cours         │
                                                    │ 📄 Documents     │
                                                    │ 💬 Chat          │
                                                    │ ⏱️ Sessions      │
                                                    └──────────────────┘
```

---

## 🗄️ STRUCTURE DE LA BASE DE DONNÉES

```
┌──────────────────────────────────────────────────────────────────┐
│                        TABLES PRINCIPALES                         │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│     USERS       │
├─────────────────┤
│ id (PK)         │
│ name            │
│ email (UNIQUE)  │
│ password        │
│ role            │ ──► 'student' | 'professor' | 'admin'
│ professorId     │ ──► Auto-généré pour les profs
│ points          │ ──► Gamification
│ streak          │ ──► Jours consécutifs d'étude
└────────┬────────┘
         │
         │ Relation 1:N
         │
    ┌────┴────┬──────────────────────────┐
    │         │                          │
    ▼         ▼                          ▼
┌─────────────────┐              ┌─────────────────┐
│    COURSES      │              │  ENROLLMENTS    │
├─────────────────┤              ├─────────────────┤
│ id (PK)         │              │ id (PK)         │
│ title           │              │ courseId (FK)   │──┐
│ description     │              │ studentId (FK)  │  │
│ professorId(FK) │◄─────────────│ status          │  │
│ examDate        │              │ requestedAt     │  │
│ status          │              └─────────────────┘  │
└────────┬────────┘                                   │
         │                                            │
         │ Relation 1:N                               │
         │                                            │
    ┌────┴────┬──────────────┬──────────────┐        │
    │         │              │              │        │
    ▼         ▼              ▼              ▼        │
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐│
│DOCUMENTS │ │ MESSAGES │ │ SESSIONS │ │ SESSIONS ││
├──────────┤ ├──────────┤ ├──────────┤ ├──────────┤│
│id (PK)   │ │id (PK)   │ │id (PK)   │ │id (PK)   ││
│courseId  │ │courseId  │ │courseId  │ │courseId  ││
│title     │ │senderId  │ │studentId │◄┘studentId ││
│filePath  │ │userName  │ │date      │  │date      ││
│uploadedAt│ │content   │ │duration  │  │duration  ││
└──────────┘ │timestamp │ │notes     │  │notes     ││
             │isPinned  │ └──────────┘  └──────────┘│
             └──────────┘                            │
                                                     │
                    Relation N:1 ────────────────────┘
```

---

## 🔐 CONTRÔLE D'ACCÈS (Permissions)

```
┌──────────────────────────────────────────────────────────────────┐
│                    MATRICE DES PERMISSIONS                        │
└──────────────────────────────────────────────────────────────────┘

                        👨‍🏫 PROFESSEUR          🎓 ÉTUDIANT
                        ─────────────          ──────────

📚 COURS
├─ Créer               ✅ OUI                  ❌ NON
├─ Voir tous           ✅ OUI (ses cours)      ✅ OUI (tous)
├─ Modifier            ✅ OUI (ses cours)      ❌ NON
├─ Supprimer           ✅ OUI (ses cours)      ❌ NON
└─ S'inscrire          ❌ NON                  ✅ OUI

📄 DOCUMENTS
├─ Uploader            ✅ OUI (ses cours)      ❌ NON
├─ Voir                ✅ OUI (ses cours)      ✅ OUI (si approuvé)
├─ Télécharger         ✅ OUI                  ✅ OUI (si approuvé)
└─ Supprimer           ✅ OUI (ses docs)       ❌ NON

👥 ENROLLMENTS
├─ Demander            ❌ NON                  ✅ OUI
├─ Voir demandes       ✅ OUI (ses cours)      ✅ OUI (ses demandes)
├─ Approuver           ✅ OUI (ses cours)      ❌ NON
└─ Rejeter             ✅ OUI (ses cours)      ❌ NON

💬 CHAT
├─ Envoyer message     ✅ OUI (ses cours)      ✅ OUI (si approuvé)
├─ Voir messages       ✅ OUI (ses cours)      ✅ OUI (si approuvé)
├─ Épingler message    ✅ OUI (ses cours)      ❌ NON
└─ Supprimer message   ✅ OUI (ses messages)   ✅ OUI (ses messages)

⏱️ SESSIONS D'ÉTUDE
├─ Créer               ❌ NON                  ✅ OUI
├─ Voir                ❌ NON                  ✅ OUI (ses sessions)
├─ Modifier            ❌ NON                  ✅ OUI (ses sessions)
└─ Supprimer           ❌ NON                  ✅ OUI (ses sessions)

🎮 GAMIFICATION
├─ Points              ❌ NON                  ✅ OUI (+10/session)
├─ Streak              ❌ NON                  ✅ OUI (auto)
└─ Classement          ❌ NON                  ✅ OUI (futur)
```

---

## 🌐 ARCHITECTURE API (Backend)

```
┌──────────────────────────────────────────────────────────────────┐
│                      ENDPOINTS API REST                           │
└──────────────────────────────────────────────────────────────────┘

🔐 AUTHENTIFICATION
├─ POST   /api/auth/register        Inscription
├─ POST   /api/auth/login           Connexion
└─ GET    /api/auth/me              Profil actuel (futur)

📚 COURS
├─ GET    /api/courses               Mes cours (prof/étudiant)
├─ GET    /api/courses/all           Tous les cours (découverte)
├─ POST   /api/courses               Créer cours (prof only)
├─ GET    /api/courses/:id           Détails d'un cours
├─ PUT    /api/courses/:id           Modifier cours (futur)
└─ DELETE /api/courses/:id           Supprimer cours (futur)

👥 ENROLLMENTS
├─ POST   /api/courses/:id/enroll                    Demander accès
├─ GET    /api/courses/:id/enrollments               Liste demandes (prof)
└─ POST   /api/courses/:cId/enrollments/:eId/approve Approuver/Rejeter

📄 DOCUMENTS
├─ GET    /api/courses/:id/documents  Liste documents
├─ POST   /api/courses/:id/documents  Upload document (prof)
└─ DELETE /api/documents/:id          Supprimer document (futur)

💬 MESSAGES (REST + Socket.IO)
├─ GET    /api/courses/:id/messages   Historique chat
└─ Socket.IO Events:
    ├─ join_room                      Rejoindre salon
    ├─ send_message                   Envoyer message
    ├─ receive_message                Recevoir message
    └─ typing                         Indicateur de frappe

⏱️ SESSIONS D'ÉTUDE
├─ GET    /api/sessions               Mes sessions
├─ POST   /api/courses/:id/sessions   Créer session
└─ DELETE /api/sessions/:id           Supprimer session (futur)
```

---

## 📱 ARCHITECTURE FRONTEND (Flutter)

```
┌──────────────────────────────────────────────────────────────────┐
│                    STRUCTURE DES ÉCRANS                           │
└──────────────────────────────────────────────────────────────────┘

lib/
├─ main.dart                          Point d'entrée
├─ screens/
│  ├─ splash_screen.dart              🌟 Écran de démarrage
│  ├─ login_screen.dart               🔐 Connexion/Inscription
│  ├─ main_screen.dart                📱 Navigation principale
│  ├─ home_screen.dart                🏠 Tableau de bord
│  ├─ courses_screen.dart             📚 Liste des cours
│  ├─ course_detail_screen.dart       📖 Détails du cours
│  ├─ chat_screen.dart                💬 Chat en temps réel
│  ├─ study_timer_screen.dart         ⏱️ Chronomètre d'étude
│  ├─ study_sessions_screen.dart      📊 Historique sessions
│  ├─ settings_screen.dart            ⚙️ Paramètres
│  ├─ admin_dashboard_screen.dart     👑 Dashboard admin
│  └─ admin_professor_management.dart 👨‍🏫 Gestion profs
│
├─ models/
│  ├─ user.dart                       👤 Modèle utilisateur
│  ├─ course.dart                     📚 Modèle cours
│  ├─ enrollment.dart                 📝 Modèle inscription
│  ├─ document.dart                   📄 Modèle document
│  ├─ message.dart                    💬 Modèle message
│  └─ study_session.dart              ⏱️ Modèle session
│
├─ providers/
│  ├─ auth_provider.dart              🔐 Gestion authentification
│  ├─ course_provider.dart            📚 Gestion cours (futur)
│  └─ chat_provider.dart              💬 Gestion chat (futur)
│
├─ services/
│  ├─ api_service.dart                🌐 Appels API (futur)
│  ├─ socket_service.dart             🔌 Socket.IO (futur)
│  └─ notification_service.dart       🔔 Notifications
│
├─ widgets/
│  └─ [Composants réutilisables]
│
├─ config/
│  └─ api_config.dart                 ⚙️ Configuration API
│
└─ theme.dart                         🎨 Thème de l'app
```

---

## 🔄 FLUX DE DONNÉES (State Management)

```
┌──────────────────────────────────────────────────────────────────┐
│                    PROVIDER PATTERN (Actuel)                      │
└──────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   UI/View   │
    │  (Screens)  │
    └──────┬──────┘
           │
           │ 1. User Action
           │    (ex: Login)
           ▼
    ┌──────────────┐
    │  Provider    │
    │ (AuthProvider│
    └──────┬───────┘
           │
           │ 2. API Call
           ▼
    ┌──────────────┐
    │  Backend API │
    │  (Express)   │
    └──────┬───────┘
           │
           │ 3. Database Query
           ▼
    ┌──────────────┐
    │   SQLite DB  │
    └──────┬───────┘
           │
           │ 4. Response
           ▼
    ┌──────────────┐
    │  Provider    │
    │ notifyListeners()
    └──────┬───────┘
           │
           │ 5. UI Update
           ▼
    ┌─────────────┐
    │   UI/View   │
    │  (Rebuild)  │
    └─────────────┘
```

---

## 🎯 SCÉNARIOS D'UTILISATION TYPIQUES

### 📖 Scénario 1 : Professeur crée un cours et gère les inscriptions

```
1. Prof se connecte
2. Va dans "My Courses"
3. Clique sur "+" pour créer un cours
4. Remplit : Titre, Description, Date d'examen
5. Cours créé ✅
6. Étudiant découvre le cours et demande accès
7. Prof reçoit notification (futur)
8. Prof va dans le cours → "Enrollments"
9. Voit la liste des demandes
10. Approuve l'étudiant
11. Étudiant reçoit notification (futur)
12. Prof upload des documents PDF
13. Étudiant peut maintenant accéder au cours et aux docs
```

### 🎓 Scénario 2 : Étudiant s'inscrit et étudie

```
1. Étudiant se connecte
2. Va dans "All Courses"
3. Parcourt la liste des cours disponibles
4. Clique sur un cours intéressant
5. Clique "Request Access"
6. Status: Pending ⏳
7. Attend l'approbation du prof
8. Reçoit notification d'approbation (futur)
9. Accède au cours
10. Télécharge les documents
11. Participe au chat avec le prof et autres étudiants
12. Lance le chronomètre d'étude
13. Gagne +10 points 🎮
14. Consulte ses statistiques
```

### 💬 Scénario 3 : Chat en temps réel

```
1. Étudiant/Prof ouvre un cours
2. Clique sur l'icône Chat 💬
3. Rejoint le salon Socket.IO
4. Voit l'historique des messages
5. Tape un message
6. Indicateur "typing..." apparaît pour les autres
7. Envoie le message
8. Message diffusé en temps réel à tous les participants
9. Message sauvegardé en DB
10. Prof peut épingler un message important
```

---

## 🚀 RECOMMANDATIONS D'AMÉLIORATION

### Phase 1 - Fondations (Semaine 1-2)
```
✅ Notifications push (Firebase)
✅ Recherche de cours
✅ Filtres et tri
✅ Calendrier des examens
```

### Phase 2 - Engagement (Semaine 3-4)
```
✅ Statistiques détaillées
✅ Graphiques de progression
✅ Amélioration du chat (fichiers, réactions)
✅ Profil utilisateur enrichi
```

### Phase 3 - Collaboration (Semaine 5-6)
```
✅ Groupes d'étude
✅ Forum Q&A
✅ Partage de notes
✅ Mode offline
```

---

## 📞 CONTACT & SUPPORT

Pour toute question sur l'architecture ou les fonctionnalités :
- Consultez `FONCTIONNALITES.md` pour la liste complète
- Consultez `README.md` pour l'installation
- Consultez `PRESENTATION.md` pour la présentation du projet
