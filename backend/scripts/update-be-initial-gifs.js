import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const mapping = JSON.parse(fs.readFileSync(path.resolve(__dirname, 'gif-mapping.json'), 'utf8'));
const mapByExId = new Map();
for (const item of mapping) {
  if (item.matchedId && item.gifFile) {
    mapByExId.set(item.matchedId, item.gifFile);
  }
}

const file = path.resolve(__dirname, '../src/exercises/data/initial-exercises.ts');
let content = fs.readFileSync(file, 'utf8');

// For each exercise id in INITIAL_EXERCISES, update gifUrl to the 3D animated GIF
for (const [id, gifFile] of mapByExId.entries()) {
  const regex = new RegExp(`(id:\\s*"${id}"[\\s\\S]*?gifUrl:\\s*")[^"]+(")`, 'g');
  content = content.replace(regex, `$1/media/exercises/${gifFile}$2`);
}

fs.writeFileSync(file, content, 'utf8');
console.log('Updated backend initial-exercises.ts with 3D GIF paths!');
