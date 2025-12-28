const db = require('./database');
const bcrypt = require('bcryptjs');

async function seed() {
    const hashedPassword = await bcrypt.hash('password', 10);

    db.serialize(() => {
        // Create Admin
        db.run('INSERT OR IGNORE INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)',
            ['admin1', 'Super Admin', 'admin@test.com', hashedPassword, 'admin'], (err) => {
                if (err) console.error('Admin error:', err.message);
            }
        );

        // Create Std User
        db.run('INSERT OR IGNORE INTO users (id, name, email, password, role) VALUES (?, ?, ?, ?, ?)',
            ['user1', 'John Student', 'student@test.com', hashedPassword, 'student'], (err) => {
                if (err) console.error('User error:', err.message);
            }
        );

        // Add some courses for John
        db.run('INSERT OR IGNORE INTO courses (id, userId, name, professor, examDate) VALUES (?, ?, ?, ?, ?)',
            ['c1', 'user1', 'Mobile Computing', 'Prof. Android', '2025-12-30T10:00:00.000Z'], (err) => {
                if (err) console.error('Course error:', err.message);
            }
        );

        console.log('Seed process finished.');
    });
}

seed();
