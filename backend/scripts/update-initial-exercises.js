import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const file = path.resolve(__dirname, '../src/exercises/data/initial-exercises.ts');
let content = fs.readFileSync(file, 'utf8');

// Replace gifUrl: "https://v2.exercisedb.io/image/..."
content = content.replace(/(id:\s*['"](\d+)['"][\s\S]*?gifUrl:\s*['"])[^'"]+(['"])/g, '$1/media/exercises/$2.jpg$3');

fs.writeFileSync(file, content, 'utf8');
console.log('Successfully updated initial-exercises.ts!');
