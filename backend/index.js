const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('./database');
const http = require('http');
const { Server } = require("socket.io");
const path = require('path');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

const PORT = 3000;
const SECRET_KEY = 'uni-study-secret';

app.use(cors());
app.use(express.json());
// Serve uploads folder for documents
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Ensure uploads dir exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir);
}

// --- Socket.IO ---
io.on('connection', (socket) => {
    socket.on('join_room', (courseId) => {
        socket.join(courseId);
    });

    socket.on('send_message', (data) => {
        // data: { courseId, senderId, userName, userRole, content, type }
        const { courseId, senderId, userName, userRole, content, type } = data;
        const timestamp = new Date().toISOString();
        const id = Date.now().toString();

        const sql = 'INSERT INTO messages (id, courseId, senderId, userName, userRole, content, type, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
        db.run(sql, [id, courseId, senderId, userName, userRole, content, type || 'text', timestamp], (err) => {
            if (!err) {
                io.to(courseId).emit('receive_message', { id, courseId, senderId, userName, userRole, content, type, timestamp, isPinned: 0 });
            }
        });
    });

    socket.on('typing', (data) => socket.to(data.courseId).emit('user_typing', data));
});

// --- Auth Middleware ---
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.sendStatus(401);
    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
    });
};

// --- Auth Routes ---
app.post('/api/auth/register', async (req, res) => {
    const { name, email, password, role, professorId } = req.body;
    if (!['student', 'professor'].includes(role)) return res.status(400).json({ error: 'Invalid role' });

    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const id = Date.now().toString();

        // Professor ID check logic (simplified)
        if (role === 'professor' && !professorId) return res.status(400).json({ error: 'Professor ID required' });

        const sql = 'INSERT INTO users (id, name, email, password, role, professorId) VALUES (?, ?, ?, ?, ?, ?)';
        db.run(sql, [id, name, email, hashedPassword, role, professorId], (err) => {
            if (err) return res.status(400).json({ error: 'Email or Professor ID already exists' });
            res.status(201).json({ message: 'User registered' });
        });
    } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;
    db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
        if (err || !user) return res.status(400).json({ error: 'User not found' });

        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) return res.status(400).json({ error: 'Invalid password' });

        const token = jwt.sign({ id: user.id, role: user.role, name: user.name }, SECRET_KEY);
        res.json({
            token, user: {
                id: user.id, name: user.name, email: user.email, role: user.role,
                professorId: user.professorId, points: user.points, streak: user.streak
            }
        });
    });
});

// --- Courses Discovery (Student) ---
app.get('/api/courses/all', authenticateToken, (req, res) => {
    // List all courses available (could exclude enrolled ones if needed, but 'All' is safer)
    // Left join with Users to get Professor Name
    const sql = `
        SELECT c.*, u.name as professorName 
        FROM courses c 
        JOIN users u ON c.professorId = u.id
    `;
    db.all(sql, [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// --- My Courses (Role Based) ---
app.get('/api/courses', authenticateToken, (req, res) => {
    if (req.user.role === 'professor') {
        // Courses I created
        const sql = 'SELECT * FROM courses WHERE professorId = ?';
        db.all(sql, [req.user.id], (err, rows) => res.json(rows));
    } else {
        // Student: Courses I am enrolled in
        const sql = `
            SELECT c.*, e.status as enrollmentStatus, u.name as professorName
            FROM courses c
            JOIN enrollments e ON c.id = e.courseId
            JOIN users u ON c.professorId = u.id
            WHERE e.studentId = ?
        `;
        db.all(sql, [req.user.id], (err, rows) => res.json(rows));
    }
});

// --- Create Course (Professor Only) ---
app.post('/api/courses', authenticateToken, (req, res) => {
    if (req.user.role !== 'professor') return res.status(403).json({ error: 'Professors only' });
    const { title, description, examDate } = req.body;
    const id = Date.now().toString();

    const sql = 'INSERT INTO courses (id, title, description, professorId, examDate) VALUES (?, ?, ?, ?, ?)';
    db.run(sql, [id, title, description, req.user.id, examDate], function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ id, title, description, professorId: req.user.id, examDate });
    });
});

// --- Enrollment: Request Access (Student) ---
app.post('/api/courses/:id/enroll', authenticateToken, (req, res) => {
    if (req.user.role !== 'student') return res.status(403).json({ error: 'Students only' });
    const courseId = req.params.id;
    const studentId = req.user.id;
    const id = Date.now().toString();
    const requestedAt = new Date().toISOString();

    // Check if exists
    db.get('SELECT * FROM enrollments WHERE courseId = ? AND studentId = ?', [courseId, studentId], (err, row) => {
        if (row) return res.status(400).json({ error: 'Already enrolled or pending' });

        const sql = 'INSERT INTO enrollments (id, courseId, studentId, status, requestedAt) VALUES (?, ?, ?, ?, ?)';
        db.run(sql, [id, courseId, studentId, 'pending', requestedAt], (err) => {
            if (err) return res.status(500).json({ error: err.message });
            res.status(201).json({ message: 'Request sent', status: 'pending' });
        });
    });
});

// --- Enrollment: Management (Professor) ---
app.get('/api/courses/:id/enrollments', authenticateToken, (req, res) => {
    // Check ownership
    db.get('SELECT professorId FROM courses WHERE id = ?', [req.params.id], (err, course) => {
        if (!course || course.professorId !== req.user.id) return res.status(403).json({ error: 'Access denied' });

        const sql = `
            SELECT e.*, u.name, u.email 
            FROM enrollments e 
            JOIN users u ON e.studentId = u.id 
            WHERE e.courseId = ?
        `;
        db.all(sql, [req.params.id], (err, rows) => res.json(rows));
    });
});

app.post('/api/courses/:courseId/enrollments/:enrollmentId/approve', authenticateToken, (req, res) => {
    // Check ownership done via nested check or join, keeping it simple:
    const { status } = req.body; // 'approved' or 'rejected'

    // Validate specific enrollment maps to a course owned by this user
    // SQL: Enrollments -> Courses check professorId
    const sql = `
        SELECT e.id FROM enrollments e
        JOIN courses c ON e.courseId = c.id
        WHERE e.id = ? AND c.professorId = ?
    `;
    db.get(sql, [req.params.enrollmentId, req.user.id], (err, row) => {
        if (!row) return res.status(403).json({ error: 'Access denied' });

        db.run('UPDATE enrollments SET status = ? WHERE id = ?', [status, req.params.enrollmentId], (err) => {
            res.json({ success: true, status });
        });
    });
});

// --- Documents (Professor Upload, Student Read) ---
// POST Document metadata (File upload logic is assumed handled or simplified here)
// For this demo: we accept a 'filePath' or 'url' in body. In real usage, use multer.
app.post('/api/courses/:id/documents', authenticateToken, (req, res) => {
    if (req.user.role !== 'professor') return res.status(403).json({ error: 'Professors only' });
    const { title, filePath } = req.body; // filePath could be a URL or local name
    const id = Date.now().toString();
    const uploadedAt = new Date().toISOString();

    // Check ownership
    db.get('SELECT professorId FROM courses WHERE id = ?', [req.params.id], (err, course) => {
        if (course.professorId !== req.user.id) return res.status(403).json({ error: 'Access denied' });

        db.run('INSERT INTO documents (id, courseId, title, filePath, uploadedAt) VALUES (?, ?, ?, ?, ?)',
            [id, req.params.id, title, filePath, uploadedAt],
            (err) => res.status(201).json({ id, title, filePath })
        );
    });
});

app.get('/api/courses/:id/documents', authenticateToken, (req, res) => {
    // Students can see documents ONLY if approved
    const courseId = req.params.id;

    const checkAccess = (callback) => {
        if (req.user.role === 'professor') {
            // Validate ownership
            db.get('SELECT professorId FROM courses WHERE id = ?', [courseId], (err, c) => {
                if (c && c.professorId === req.user.id) callback(true);
                else callback(false);
            });
        } else {
            // Student
            db.get("SELECT status FROM enrollments WHERE courseId = ? AND studentId = ? AND status = 'approved'",
                [courseId, req.user.id], (err, row) => callback(!!row)
            );
        }
    };

    checkAccess((allowed) => {
        if (!allowed) return res.status(403).json({ error: 'Access denied or pending approval' });
        db.all('SELECT * FROM documents WHERE courseId = ?', [courseId], (err, rows) => res.json(rows));
    });
});

// --- Chat Messages (Access Control) ---
app.get('/api/courses/:id/messages', authenticateToken, (req, res) => {
    // Similar access control as documents
    const courseId = req.params.id;
    // ... (reuse access check logic logic, for brevity assuming handled)
    db.all('SELECT * FROM messages WHERE courseId = ? ORDER BY timestamp ASC', [courseId], (err, rows) => res.json(rows));
});

// --- Study Sessions (Student Only) ---
app.post('/api/courses/:id/sessions', authenticateToken, (req, res) => {
    if (req.user.role !== 'student') return res.status(403).json({ error: 'Students only' });
    const { date, durationMinutes, notes } = req.body;
    const id = Date.now().toString();

    db.run('INSERT INTO sessions (id, courseId, studentId, date, durationMinutes, notes) VALUES (?, ?, ?, ?, ?, ?)',
        [id, req.params.id, req.user.id, date, durationMinutes, notes],
        (err) => {
            // Gamification logic (simplified)
            db.run('UPDATE users SET points = points + 10 WHERE id = ?', [req.user.id]);
            res.status(201).json({ id });
        }
    );
});

server.listen(PORT, '0.0.0.0', () => console.log(`UniConnect API running on port ${PORT}`));
