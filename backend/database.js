const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'study_planner.db');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database', err.message);
    } else {
        console.log('Connected to the SQLite database.');
        db.serialize(() => {
            // Create Users Table (updated with points, streaks, and professorId)
            db.run(`CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'student',
        professorId TEXT UNIQUE,
        points INTEGER DEFAULT 0,
        streak INTEGER DEFAULT 0,
        lastStudyDate TEXT
      )`, (err) => {
                if (!err) {
                    db.run('ALTER TABLE users ADD COLUMN points INTEGER DEFAULT 0', (err) => { });
                    db.run('ALTER TABLE users ADD COLUMN streak INTEGER DEFAULT 0', (err) => { });
                    db.run('ALTER TABLE users ADD COLUMN lastStudyDate TEXT', (err) => { });
                    db.run('ALTER TABLE users ADD COLUMN professorId TEXT UNIQUE', (err) => { });
                }
            });

            // Create Courses Table (updated with notes)
            db.run(`CREATE TABLE IF NOT EXISTS courses (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        professor TEXT,
        examDate TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        grade INTEGER,
        notes TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )`, (err) => {
                if (!err) {
                    db.run('ALTER TABLE courses ADD COLUMN status TEXT DEFAULT "active"', (err) => { });
                    db.run('ALTER TABLE courses ADD COLUMN grade INTEGER', (err) => { });
                    db.run('ALTER TABLE courses ADD COLUMN notes TEXT', (err) => { });
                }
            });

            // Create Sessions Table
            db.run(`CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        date TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        notes TEXT,
        type TEXT DEFAULT 'stopwatch',
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )`, (err) => {
                if (!err) {
                    db.run('ALTER TABLE sessions ADD COLUMN type TEXT DEFAULT "stopwatch"', (err) => { });
                }
            });

            // Create Messages Table
            db.run(`CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userRole TEXT,
        content TEXT NOT NULL,
        type TEXT DEFAULT 'text',
        timestamp TEXT NOT NULL,
        isPinned INTEGER DEFAULT 0
      )`, (err) => {
                if (err) console.error("Error creating messages table:", err.message);
            });
        });
    }
});

module.exports = db;
