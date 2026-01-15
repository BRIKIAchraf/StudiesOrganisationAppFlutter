const fs = require('fs');
const path = require('path');

console.log('Current directory:', process.cwd());
console.log('Resolving ../middleware/auth from ./routes/study-groups.js context');

const routesDir = path.join(__dirname, 'routes');
const middlewareDir = path.join(__dirname, 'middleware');
const authFile = path.join(middlewareDir, 'auth.js');

console.log('Routes Dir exists:', fs.existsSync(routesDir));
console.log('Middleware Dir exists:', fs.existsSync(middlewareDir));
console.log('Auth File exists:', fs.existsSync(authFile));

try {
    const auth = require('./middleware/auth');
    console.log('Successfully required ./middleware/auth from root');
} catch (e) {
    console.error('Failed to require ./middleware/auth from root:', e.message);
}

try {
    // Simulate routes/study-groups.js context
    module.paths.push(routesDir);
    // This isn't exactly how require works but let's try to resolve relative
    const resolvedPath = path.resolve(routesDir, '../middleware/auth');
    console.log('Calculated resolution path:', resolvedPath);
    console.log('Does calculated path exist?', fs.existsSync(resolvedPath + '.js'));
} catch (e) {
    console.error('Error during simulation:', e);
}
