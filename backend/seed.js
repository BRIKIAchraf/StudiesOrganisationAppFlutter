const db = require('./database');
const bcrypt = require('bcryptjs');

async function seed() {
    console.log('Starting seed process...');
    const hashedPassword = await bcrypt.hash('password', 10);

    db.serialize(() => {
        // 1. Users
        console.log('Seeding Users...');
        // Create Admin
        db.run('INSERT OR IGNORE INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)',
            ['admin1', 'Super Admin', 'admin@test.com', hashedPassword, 'admin']);

        // Create 15 Professors
        const professors = [];
        for (let i = 1; i <= 15; i++) {
            const id = `prof${i}`;
            professors.push(id);
            db.run('INSERT OR IGNORE INTO users (id, name, email, password, role, professorId) VALUES (?, ?, ?, ?, ?, ?)',
                [id, `Professor ${i}`, `prof${i}@univ.edu`, hashedPassword, 'professor', `PROF_ID_${i}`]);
        }

        // Create 15 Students
        const students = [];
        for (let i = 1; i <= 15; i++) {
            const id = `student${i}`;
            students.push(id);
            // Random stats
            const points = Math.floor(Math.random() * 5000);
            const streak = Math.floor(Math.random() * 100);
            db.run('INSERT OR IGNORE INTO users (id, name, email, password, role, points, streak) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [id, `Student ${i}`, `student${i}@univ.edu`, hashedPassword, 'student', points, streak]);
        }

        // 2. Courses (15 courses)
        console.log('Seeding Courses...');
        const courses = [];
        const courseTitles = [
            'Mobile Computing', 'Advanced Algorithms', 'Database Systems', 'Web Development', 'Machine Learning',
            'Artificial Intelligence', 'Cyber Security', 'Cloud Computing', 'Operating Systems', 'Computer Networks',
            'Software Engineering', 'Human Computer Interaction', 'Data Science', 'Blockchain Basics', 'IoT Fundamentals'
        ];

        for (let i = 0; i < 15; i++) {
            const id = `course${i + 1}`;
            courses.push(id);
            const pId = professors[i % professors.length]; // Distribute courses among professors
            const examDate = new Date();
            examDate.setDate(examDate.getDate() + 30 + (i * 2)); // Future dates

            db.run('INSERT OR IGNORE INTO courses (id, title, description, professorId, examDate) VALUES (?, ?, ?, ?, ?)',
                [id, courseTitles[i], `Comprehensive course on ${courseTitles[i]}. Covers basics to advanced topics.`, pId, examDate.toISOString()]);
        }

        // 3. Enrollments (15 enrollments - ensuring every student has at least one course)
        console.log('Seeding Enrollments...');
        for (let i = 0; i < 15; i++) {
            const sId = students[i];
            const cId = courses[i % courses.length]; // Assign course i to student i
            const eId = `enr${i + 1}`;
            db.run('INSERT OR IGNORE INTO enrollments (id, courseId, studentId, status, requestedAt) VALUES (?, ?, ?, ?, ?)',
                [eId, cId, sId, 'approved', new Date().toISOString()]);

            // Add a second random course for some variety
            if (i % 2 === 0) {
                const cId2 = courses[(i + 5) % courses.length];
                const eId2 = `enr${i + 1}_b`;
                db.run('INSERT OR IGNORE INTO enrollments (id, courseId, studentId, status, requestedAt) VALUES (?, ?, ?, ?, ?)',
                    [eId2, cId2, sId, 'pending', new Date().toISOString()]);
            }
        }

        // 4. Documents (15 docs)
        console.log('Seeding Documents...');
        for (let i = 1; i <= 15; i++) {
            const cId = courses[i % courses.length];
            db.run('INSERT OR IGNORE INTO documents (id, courseId, title, filePath, uploadedAt) VALUES (?, ?, ?, ?, ?)',
                [`doc${i}`, cId, `Lecture Notes Week ${i}`, `assets/pdfs/lecture_${i}.pdf`, new Date().toISOString()]);
        }

        // 5. Messages (15 messages)
        console.log('Seeding Messages...');
        for (let i = 1; i <= 15; i++) {
            const cId = courses[i % courses.length];
            const sId = students[i % students.length];
            db.run('INSERT OR IGNORE INTO messages (id, courseId, senderId, userName, userRole, content, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [`msg${i}`, cId, sId, `Student ${i}`, 'student', `Hello, I have a question about the assignment ${i}.`, new Date().toISOString()]);
        }

        // 6. Sessions (15 sessions)
        console.log('Seeding Sessions...');
        for (let i = 1; i <= 15; i++) {
            const cId = courses[i % courses.length];
            const sId = students[i % students.length];
            db.run('INSERT OR IGNORE INTO sessions (id, courseId, studentId, date, durationMinutes, notes) VALUES (?, ?, ?, ?, ?, ?)',
                [`sess${i}`, cId, sId, new Date().toISOString(), 45 + (i * 5), `Focused study session for ${i} minutes.`]);
        }

        console.log('Seed process finished. 15+ items generated for each category.');
    });
}

seed();
