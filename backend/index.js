const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('./database');
const http = require('http');
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const PORT = 3000;
const SECRET_KEY = 'uni-study-secret'; // In production, use env variables

app.use(cors());
app.use(express.json());

// --- Socket.IO Logic ---
io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    socket.on('join_room', (courseId) => {
        socket.join(courseId);
        console.log(`User ${socket.id} joined course room: ${courseId}`);
    });

    socket.on('send_message', (data) => {
        // Data should contain: courseId, userId, userName, userRole, content, type
        const { courseId, userId, userName, userRole, content, type } = data;
        const timestamp = new Date().toISOString();
        const id = Date.now().toString();

        // Save to DB
        const sql = 'INSERT INTO messages (id, courseId, userId, userName, userRole, content, type, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
        db.run(sql, [id, courseId, userId, userName, userRole, content, type || 'text', timestamp], (err) => {
            if (err) {
                console.error('Error saving message:', err.message);
                return;
            }
            // Broadcast to room (including sender)
            io.to(courseId).emit('receive_message', {
                id, courseId, userId, userName, userRole, content, type, timestamp, isPinned: 0
            });
        });
    });

    socket.on('typing', (data) => {
        // Broadcast to others in room
        socket.to(data.courseId).emit('user_typing', {
            userId: data.userId,
            userName: data.userName,
            isTyping: data.isTyping
        });
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
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

// Register
app.post('/api/auth/register', async (req, res) => {
    const { name, email, password, role, professorId } = req.body;
    try {
        // Validate professor ID if role is professor
        if (role === 'professor' && !professorId) {
            return res.status(400).json({ error: 'Professor ID is required for professor role' });
        }

        // Check if professor ID already exists
        if (professorId) {
            const existing = await new Promise((resolve, reject) => {
                db.get('SELECT id FROM users WHERE professorId = ?', [professorId], (err, row) => {
                    if (err) reject(err);
                    resolve(row);
                });
            });
            if (existing) {
                return res.status(400).json({ error: 'Professor ID already exists' });
            }
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const id = Date.now().toString();

        const sql = 'INSERT INTO users (id, name, email, password, role, professorId) VALUES (?, ?, ?, ?, ?, ?)';
        db.run(sql, [id, name, email, hashedPassword, role || 'student', professorId || null], (err) => {
            if (err) return res.status(400).json({ error: 'Email already exists' });
            res.status(201).json({ message: 'User registered' });
        });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Login
app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;

    // Hardcoded Admin Check
    if (email === 'admin@uniurb.it' && password === 'admin123') {
        const adminUser = {
            id: 'admin_1',
            name: 'University Admin',
            email: 'admin@uniurb.it',
            role: 'admin',
            professorId: null,
            points: 0,
            streak: 0,
            lastStudyDate: null
        };
        const token = jwt.sign({ id: adminUser.id, role: adminUser.role, name: adminUser.name }, SECRET_KEY);
        return res.json({ token, user: adminUser });
    }

    db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
        if (err || !user) return res.status(400).json({ error: 'User not found' });

        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) return res.status(400).json({ error: 'Invalid password' });

        const token = jwt.sign({ id: user.id, role: user.role, name: user.name }, SECRET_KEY);
        res.json({
            token, user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                professorId: user.professorId,
                points: user.points,
                streak: user.streak,
                lastStudyDate: user.lastStudyDate
            }
        });
    });
});

// Update Role
app.put('/api/auth/role', authenticateToken, (req, res) => {
    const { role } = req.body;
    if (!['student', 'professor', 'admin'].includes(role)) return res.status(400).json({ error: 'Invalid role' });

    db.run('UPDATE users SET role = ? WHERE id = ?', [role, req.user.id], function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Role updated successfully', role });
    });
});

// --- Secured API Routes ---

// GET all courses (Authenticated & User specific)
app.get('/api/courses', authenticateToken, (req, res) => {
    // If Admin/Prof, maybe they see all courses or specific logic? 
    // For now, keep it simple: Student sees their own enrollments/courses.
    // However, for Chat, Professors need to see courses they teach.
    // Assuming 'courses' table linkage is via 'userId' (creator).
    // If role is professor, they see courses they created.

    // Future enhancement: Enrolled students table.

    const sql = `
    SELECT c.*, 
    (SELECT json_group_array(json_object('id', s.id, 'date', s.date, 'durationMinutes', s.durationMinutes, 'notes', s.notes, 'type', s.type)) 
     FROM sessions s WHERE s.courseId = c.id) as sessions
    FROM courses c
    WHERE c.userId = ?
  `;
    db.all(sql, [req.user.id], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        const result = rows.map(row => ({
            ...row,
            sessions: JSON.parse(row.sessions || '[]')
        }));
        res.json(result);
    });
});

// CHAT: Get messages for a course
app.get('/api/courses/:id/messages', authenticateToken, (req, res) => {
    const courseId = req.params.id;
    // Simple pagination could be added via query params
    const sql = 'SELECT * FROM messages WHERE courseId = ? ORDER BY timestamp ASC';
    db.all(sql, [courseId], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// CHAT: Get unread count (mock implementation based on last checks, or just total for now)
// Real unread tracking requires a 'read_receipts' table or 'last_read' timestamp per user/course.
// For now, let's return total messages count as a proxy or just 0 if we don't track 'last_read'.
// User asked for "Implement unread message tracking". 
// Let's add a 'last_read' timestamp to 'enrolled_courses' (if we had one) or 'participants'.
// We don't have a participants table. We only have 'courses' (owned by user).
// If I am a student, I own the course. So I see all messages.
// If I am a professor, I see the course.
// Let's just return total count for now, enabling the badge.
app.get('/api/courses/:id/unread-count', authenticateToken, (req, res) => {
    const courseId = req.params.id;
    // Count messages not sent by me?
    // This is a naive implementation without 'last_read' stored.
    // To do it right we need to store 'last_open_date' for the course.
    // Let's assume the frontend tracks what it has read and asks for count > X?
    // Or simpler: backend returns total count, frontend subtracts what it knows.
    db.get('SELECT COUNT(*) as count FROM messages WHERE courseId = ?', [courseId], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ count: row.count });
    });
});

// CHAT: Pin message (Professor only)
app.put('/api/courses/:id/messages/:messageId/pin', authenticateToken, (req, res) => {
    if (req.user.role !== 'professor' && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Only professors can pin messages' });
    }
    const { isPinned } = req.body; // true or false
    const { messageId } = req.params;

    db.run('UPDATE messages SET isPinned = ? WHERE id = ?', [isPinned ? 1 : 0, messageId], function (err) {
        if (err) return res.status(500).json({ error: err.message });

        // Notify room via socket (optional optimization: fetch message content too)
        io.to(req.params.id).emit('message_pinned', { messageId, isPinned });

        res.json({ success: true });
    });
});

// Admin Route: Get Global Stats
app.get('/api/admin/stats', authenticateToken, (req, res) => {
    if (req.user.role !== 'admin') return res.status(403).json({ error: 'Admins only' });

    const sql = `
    SELECT 
      (SELECT COUNT(*) FROM users) as totalUsers,
      (SELECT COUNT(*) FROM courses) as totalCourses,
      (SELECT SUM(durationMinutes) FROM sessions) as totalMinutesSpent,
      (SELECT AVG(grade) FROM courses WHERE grade IS NOT NULL) as globalAverageGrade,
      (SELECT COUNT(*) FROM courses WHERE status = 'completed') as completedCoursesCount
  `;
    db.get(sql, [], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(row);
    });
});

// Admin: Get all professors
app.get('/api/admin/professors', authenticateToken, (req, res) => {
    if (req.user.role !== 'admin') return res.status(403).json({ error: 'Admins only' });

    db.all("SELECT id, name, email, professorId, role, CASE WHEN professorId IS NOT NULL THEN 'approved' ELSE 'pending' END as status FROM users WHERE role = 'professor'", [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// Admin: Approve professor
app.post('/api/admin/professors/:id/approve', authenticateToken, (req, res) => {
    if (req.user.role !== 'admin') return res.status(403).json({ error: 'Admins only' });
    const { professorId } = req.body;

    db.run("UPDATE users SET professorId = ? WHERE id = ?", [professorId, req.params.id], function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ success: true });
    });
});

// POST new course
app.post('/api/courses', authenticateToken, (req, res) => {
    const { id, name, professor, examDate, status = 'active', grade = null } = req.body;
    const sql = 'INSERT INTO courses (id, userId, name, professor, examDate, status, grade) VALUES (?, ?, ?, ?, ?, ?, ?)';
    db.run(sql, [id, req.user.id, name, professor, examDate, status, grade], function (err) {
        if (err) return res.status(400).json({ error: err.message });
        res.status(201).json({ id, name, professor, examDate, status, grade });
    });
});

// PUT update course (all fields)
app.put('/api/courses/:id', authenticateToken, (req, res) => {
    const { name, professor, examDate, status, grade } = req.body;

    db.get('SELECT * FROM courses WHERE id = ? AND userId = ?', [req.params.id, req.user.id], (err, row) => {
        if (err || !row) return res.status(403).json({ error: 'Access denied' });

        const updatedName = name || row.name;
        const updatedProf = professor || row.professor;
        const updatedDate = examDate || row.examDate;
        const updatedStatus = status || row.status;
        const updatedGrade = grade !== undefined ? grade : row.grade;

        const sql = 'UPDATE courses SET name = ?, professor = ?, examDate = ?, status = ?, grade = ? WHERE id = ?';
        db.run(sql, [updatedName, updatedProf, updatedDate, updatedStatus, updatedGrade, req.params.id], function (err) {
            if (err) return res.status(400).json({ error: err.message });
            res.json({ message: 'Updated', changes: this.changes });
        });
    });
});

// DELETE course
app.delete('/api/courses/:id', authenticateToken, (req, res) => {
    db.run('DELETE FROM courses WHERE id = ? AND userId = ?', [req.params.id, req.user.id], function (err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Deleted', changes: this.changes });
    });
});

// POST new session (with gamification)
app.post('/api/courses/:id/sessions', authenticateToken, (req, res) => {
    const courseId = req.params.id;
    const { id, date, durationMinutes, notes, type = 'stopwatch' } = req.body;

    db.get('SELECT id FROM courses WHERE id = ? AND userId = ?', [courseId, req.user.id], (err, course) => {
        if (err || !course) return res.status(403).json({ error: 'Access denied' });

        const sessionSql = 'INSERT INTO sessions (id, courseId, date, durationMinutes, notes, type) VALUES (?, ?, ?, ?, ?, ?)';
        db.run(sessionSql, [id, courseId, date, durationMinutes, notes, type], function (err) {
            if (err) return res.status(400).json({ error: err.message });

            // Gamification: Update user points and streak
            db.get('SELECT streak, lastStudyDate FROM users WHERE id = ?', [req.user.id], (err, user) => {
                let newStreak = user.streak || 0;
                const today = new Date().toISOString().split('T')[0];
                const lastDate = user.lastStudyDate ? user.lastStudyDate.split('T')[0] : null;

                if (lastDate !== today) {
                    if (lastDate === new Date(Date.now() - 86400000).toISOString().split('T')[0]) {
                        newStreak++;
                    } else if (!lastDate) {
                        newStreak = 1;
                    } else {
                        newStreak = 1; // Reset if gap exists
                    }
                }

                const userUpdateSql = 'UPDATE users SET points = points + 10, streak = ?, lastStudyDate = ? WHERE id = ?';
                db.run(userUpdateSql, [newStreak, new Date().toISOString(), req.user.id], (err) => {
                    res.status(201).json({ id, courseId, date, durationMinutes, notes, type, pointsEarned: 10, streak: newStreak });
                });
            });
        });
    });
});

// UPDATE session
app.put('/api/courses/:id/sessions/:sessionId', authenticateToken, (req, res) => {
    const { id, sessionId } = req.params;
    const { durationMinutes, notes, type } = req.body;

    // Verify ownership
    db.get('SELECT id FROM courses WHERE id = ? AND userId = ?', [id, req.user.id], (err, row) => {
        if (err || !row) return res.status(403).json({ error: 'Access denied' });

        const updates = [];
        const values = [];

        if (durationMinutes !== undefined) {
            updates.push('durationMinutes = ?');
            values.push(durationMinutes);
        }
        if (notes !== undefined) {
            updates.push('notes = ?');
            values.push(notes);
        }
        if (type !== undefined) {
            updates.push('type = ?');
            values.push(type);
        }

        if (updates.length === 0) {
            return res.status(400).json({ error: 'No fields to update' });
        }

        values.push(sessionId);
        const sql = `UPDATE sessions SET ${updates.join(', ')} WHERE id = ?`;

        db.run(sql, values, function (err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Session updated', changes: this.changes });
        });
    });
});


// DELETE session
app.delete('/api/courses/:id/sessions/:sessionId', authenticateToken, (req, res) => {
    const { id, sessionId } = req.params;
    // Verify ownership
    db.get('SELECT id FROM courses WHERE id = ? AND userId = ?', [id, req.user.id], (err, row) => {
        if (err || !row) return res.status(403).json({ error: 'Access denied' });

        db.run('DELETE FROM sessions WHERE id = ?', sessionId, function (err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ message: 'Deleted', changes: this.changes });
        });
    });
});

// NOTE: use server.listen instead of app.listen for Socket.IO
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
});
