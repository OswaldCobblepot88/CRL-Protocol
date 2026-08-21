const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const artifactPath = path.join(__dirname, '..', 'out', 'VariableDebtToken.sol', 'VariableDebtTokenA.json');

try {
  const pkg = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
  
  if (pkg.scripts && pkg.scripts.postinstall) {
    execSync(pkg.scripts.postinstall, { stdio: 'inherit' });
  }
} catch (err) {
  // Если файла нет при обычной установке зависимостей — просто игнорируем
  // Ошибку покажем только если запустили явно
  if (process.env.npm_lifecycle_event === 'prepare' && fs.existsSync(artifactPath)) {
    console.error(err);
    process.exit(1);
  }
}
