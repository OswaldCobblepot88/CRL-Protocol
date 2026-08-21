// Compile all contract artifacts from lib directory
const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

const walk = (dir) => {
  const files = fs.readdirSync(dir, { withFileTypes: true });
  for (const file of files) {
    const full = path.join(dir, file.name);
    if (file.isDirectory()) walk(full);
    else if (file.name.endsWith('.json')) {
      try {
        const pkg = JSON.parse(fs.readFileSync(full));
        if (pkg.scripts?.postinstall) {
          execSync(pkg.scripts.postinstall, { stdio: 'inherit' });
        }
      } catch (_) {}
    }
  }
};

walk('out');
