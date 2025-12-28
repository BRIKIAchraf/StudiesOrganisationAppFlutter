# University Study Planner
**Student:** [Name Surname]  
**Matricola:** [123456]  
**Course:** Mobile Computing 2024/2025

## Project Description
This application is a study planner designed to help university students manage their courses, track upcoming exams, and log their study sessions. I built this app because I often forget how much time I spend studying for each subject, and I wanted a simple tool to visualize my progress.

## Features
1. **Course Management**: Add courses with professor names and exam dates.
2. **Exam Tracking**: The home screen shows the next upcoming exam and a countdown.
3. **Study Sessions**: Log study time (minutes) and notes for each course.
4. **Persistence**: All data is saved on the device so it's not lost when closing the app.
5. **Daily Tips**: Fetches a random study tip or advice from the internet.
6. **Responsive**: Works on phones and tablets (split view implemented).

## 📚 Documentation & Setup
To manage this project like a professional developer, please refer to the following guides:

1. [**Developer Guide**](./docs/DEVELOPER_GUIDE.md): Architecture, feature logic, and database schema.
2. [**Physical Device Deployment**](./docs/PHYSICAL_DEVICE_GUIDE.md): How to run the app on your mobile phone and fix network issues.

## 🚀 Quick Run
1. Start Backend: `cd backend && node index.js`
2. Run App: `flutter run` (Ensure your IP is set in `lib/config/api_config.dart`)

## 🛠️ Main Features
- **Smart Study Suggestions**: AI-lite algorithm to prioritize subjects.
- **Pomodoro Timer**: focus intervals with local notifications.
- **Academic Gamification**: Points, daily streaks, and achievement badges.
- **Premium UI**: Adaptive split-pane view for tablets and glassmorphism design.
- **Markdown Notes**: Rich-text notes for every course.

