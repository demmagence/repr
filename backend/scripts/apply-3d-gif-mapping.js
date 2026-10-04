import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const mapping = JSON.parse(fs.readFileSync(path.resolve(__dirname, 'gif-mapping.json'), 'utf8'));
const mapBySeedName = new Map();
for (const item of mapping) {
  mapBySeedName.set(item.seedName.trim().toLowerCase(), item);
}

// 1. Update frontend/lib/data/seed_exercises.dart
const seedFile = path.resolve(__dirname, '../../frontend/lib/data/seed_exercises.dart');
const seedContent = fs.readFileSync(seedFile, 'utf8');

const parts = seedContent.split('SeedExerciseItem(');
const header = parts[0];
const updatedItems = [];

let updatedCount = 0;
for (let i = 1; i < parts.length; i++) {
  let block = parts[i];
  // extract name
  const nameMatch = block.match(/name:\s*"([^"]+)"/);
  if (nameMatch) {
    const seedName = nameMatch[1];
    const data = mapBySeedName.get(seedName.trim().toLowerCase());
    if (data && data.gifFile) {
      const newGifUrl = `/media/exercises/${data.gifFile}`;
      if (block.includes('gifUrl:')) {
        block = block.replace(/gifUrl:\s*("[^"]*"|null)/, `gifUrl: "${newGifUrl}"`);
      } else {
        if (block.includes('target:')) {
          block = block.replace(/(target:\s*"[^"]*",)/, `$1\n    gifUrl: "${newGifUrl}",`);
        } else if (block.includes('equipment:')) {
          block = block.replace(/(equipment:\s*"[^"]*",)/, `$1\n    gifUrl: "${newGifUrl}",`);
        }
      }
      updatedCount++;
    }
  }
  updatedItems.push(block);
}

const newSeedContent = header + updatedItems.map(item => 'SeedExerciseItem(' + item).join('');
fs.writeFileSync(seedFile, newSeedContent, 'utf8');
console.log(`Updated frontend/lib/data/seed_exercises.dart: ${updatedCount} items now have gifUrl!`);

// 2. Update backend/src/exercises/data/initial-exercises.ts
const backendFile = path.resolve(__dirname, '../src/exercises/data/initial-exercises.ts');
let backendContent = fs.readFileSync(backendFile, 'utf8');

let beUpdated = 0;
for (const [nameLower, data] of mapBySeedName.entries()) {
  if (!data.gifFile) continue;
  const newGifUrl = `/media/exercises/${data.gifFile}`;
  const beRegex = new RegExp(`(name:\\s*"${escapeRegex(data.seedName)}"[\\s\\S]*?gifUrl:\\s*")[^"]+(")`, 'i');
  if (beRegex.test(backendContent)) {
    backendContent = backendContent.replace(beRegex, `$1${newGifUrl}$2`);
    beUpdated++;
  }
}

function escapeRegex(string) {
  return string.replace(/[/\-\\^$*+?.()|[\]{}]/g, '\\$&');
}

fs.writeFileSync(backendFile, backendContent, 'utf8');
console.log(`Updated backend initial-exercises.ts: ${beUpdated} items updated!`);
