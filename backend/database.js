const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'study_planner.db');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database', err.message);
    } else {
        console.log('Connected to the SQLite database.');
        db.serialize(() => {
            // 1. Users Table
            // Strict role check enforced via app logic, constrained here for consistency
            // professorId is for Professors to share with students or admin tracking
            db.run(`CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                role TEXT CHECK(role IN ('student', 'professor')) NOT NULL DEFAULT 'student',
                professorId TEXT UNIQUE, 
                points INTEGER DEFAULT 0,
                streak INTEGER DEFAULT 0,
                lastStudyDate TEXT
            )`);

            // 2. Courses Table
            // Owned by a Professor (userId -> professorId semantic link)
            db.run(`CREATE TABLE IF NOT EXISTS courses (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT,
                professorId TEXT NOT NULL,
                examDate TEXT,
                status TEXT DEFAULT 'active',
                FOREIGN KEY (professorId) REFERENCES users (id) ON DELETE CASCADE
            )`);

            // 3. Enrollments Table
            // Links Students to Courses
            db.run(`CREATE TABLE IF NOT EXISTS enrollments (
                id TEXT PRIMARY KEY,
                courseId TEXT NOT NULL,
                studentId TEXT NOT NULL,
                status TEXT DEFAULT 'pending', -- pending, approved, rejected
                requestedAt TEXT NOT NULL,
                FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE,
                FOREIGN KEY (studentId) REFERENCES users (id) ON DELETE CASCADE
            )`);

            // 4. Documents Table
            // PDF files uploaded by Professor
            db.run(`CREATE TABLE IF NOT EXISTS documents (
                id TEXT PRIMARY KEY,
                courseId TEXT NOT NULL,
                title TEXT NOT NULL,
                filePath TEXT NOT NULL, -- Local path or URL
                uploadedAt TEXT NOT NULL,
                FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
            )`);

            // 5. Messages Table
            // Real-time chat history
            db.run(`CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                courseId TEXT NOT NULL,
                senderId TEXT NOT NULL,
                userName TEXT NOT NULL, -- Denormalized for ease
                userRole TEXT,          -- Denormalized for ease
                content TEXT NOT NULL,
                type TEXT DEFAULT 'text',
                timestamp TEXT NOT NULL,
                isPinned INTEGER DEFAULT 0,
                FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE,
                FOREIGN KEY (senderId) REFERENCES users (id) ON DELETE CASCADE
            )`);

            // 6. Sessions (Study Sessions)
            // Kept for student study tracking (linked to course & student)
            // Note: In strict mode, student only adds sessions to courses they are enrolled in.
            // But we keep it simple: linked to courseId. StudentId is implicit owner? 
            // Wait, original schema had sessions linked to course, and course linked to User.
            // NOW: Course owned by Prof. Student has Enrollment.
            // Updates: Sessions must link to Student (UserId) AND Course.
            // Original: sessions (id, courseId, date, duration, notes).
            // We need to add studentId to sessions to distinguish who studied.
            db.run(`CREATE TABLE IF NOT EXISTS sessions (
                id TEXT PRIMARY KEY,
                courseId TEXT NOT NULL,
                studentId TEXT NOT NULL,
                date TEXT NOT NULL,
                durationMinutes INTEGER NOT NULL,
                notes TEXT,
                type TEXT DEFAULT 'stopwatch',
                FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE,
                FOREIGN KEY (studentId) REFERENCES users (id) ON DELETE CASCADE
            )`);

        });
    }
});

module.exports = db;
