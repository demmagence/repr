import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const DATASET_URL = 'https://raw.githubusercontent.com/Johnson-Jia/Exercises-Dataset/main/data/exercises.json';
const MEDIA_BASE_URL = 'https://raw.githubusercontent.com/Johnson-Jia/Exercises-Dataset/main/';

const backendPublicDir = path.resolve(__dirname, '../public/exercises');
const frontendAssetDir = path.resolve(__dirname, '../../frontend/assets/exercises');
const seedFilePath = path.resolve(__dirname, '../../frontend/lib/data/seed_exercises.dart');

if (!fs.existsSync(backendPublicDir)) fs.mkdirSync(backendPublicDir, { recursive: true });
if (!fs.existsSync(frontendAssetDir)) fs.mkdirSync(frontendAssetDir, { recursive: true });

function normalize(str) {
  return (str || '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

async function run() {
  console.log('Fetching ExerciseDB 3D animations dataset (1,324 exercises)...');
  const res = await fetch(DATASET_URL);
  const dataset = await res.json();
  console.log(`Loaded ${dataset.length} exercises from dataset.`);

  const seedContent = fs.readFileSync(seedFilePath, 'utf8');

  // Regex to parse SeedExerciseItem entries
  const itemRegex = /SeedExerciseItem\(\s*name:\s*"([^"]+)",\s*muscle:\s*"([^"]+)",\s*equipment:\s*"([^"]+)"/g;
  let match;
  const seedItems = [];
  while ((match = itemRegex.exec(seedContent)) !== null) {
    seedItems.push({
      name: match[1],
      muscle: match[2],
      equipment: match[3],
    });
  }

  console.log(`Parsed ${seedItems.length} seed items from seed_exercises.dart.`);

  // Custom aliases for edge-case exercise names
  const customAliases = {
    'Machine Shoulder Press': 'lever military press',
    'Rear Delt Fly': 'dumbbell rear fly',
    'Face Pull': 'cable standing rear delt row (with rope)',
    'Bulgarian Split Squat': 'dumbbell single leg split squat',
    'Ab Wheel Rollout': 'wheel rollerout',
  };

  // Find match for each seedItem
  const mapping = [];
  for (const item of seedItems) {
    const aliasName = customAliases[item.name];
    let found = null;
    if (aliasName) {
      found = dataset.find(e => normalize(e.name) === normalize(aliasName));
    }

    const normName = normalize(item.name);
    const normEquip = normalize(item.equipment);

    // 1. Exact name match
    if (!found) {
      found = dataset.find(e => normalize(e.name) === normName);
    }

    // 2. Contains match with equipment
    if (!found) {
      found = dataset.find(e => {
        const dName = normalize(e.name);
        const dEquip = normalize(e.equipment);
        return (dName.includes(normName) || normName.includes(dName)) && (dEquip.includes(normEquip) || normEquip.includes(dEquip));
      });
    }

    // 3. Relaxed contains match
    if (!found) {
      found = dataset.find(e => {
        const dName = normalize(e.name);
        return dName.includes(normName) || normName.includes(dName);
      });
    }

    // 4. Word overlap match
    if (!found) {
      const words = normName.split(' ').filter(w => w.length > 2);
      found = dataset.find(e => {
        const dName = normalize(e.name);
        return words.every(w => dName.includes(w));
      });
    }

    // 5. Fallback: match by equipment & muscle/target
    if (!found) {
      found = dataset.find(e => {
        const dEquip = normalize(e.equipment);
        const dTarget = normalize(e.target);
        return dEquip.includes(normEquip) && dTarget.includes(normalize(item.muscle));
      });
    }

    mapping.push({
      seedItem: item,
      matched: found,
    });
  }

  const matchedCount = mapping.filter(m => m.matched).length;
  console.log(`Successfully mapped ${matchedCount} / ${seedItems.length} exercises to 3D GIFs!`);

  // Download GIF files and record filename
  const downloadedMap = new Map(); // media_id -> local filename
  for (const entry of mapping) {
    if (!entry.matched || !entry.matched.image) continue;
    const remotePath = entry.matched.image; // e.g. "media/EIeI8Vf.gif"
    const mediaId = entry.matched.media_id || path.basename(remotePath, '.gif');
    const safeFilename = `${entry.matched.id}_${mediaId}.gif`;
    entry.localGifFilename = safeFilename;

    if (!downloadedMap.has(mediaId)) {
      const fullUrl = `${MEDIA_BASE_URL}${remotePath}`;
      const backendDest = path.join(backendPublicDir, safeFilename);
      const frontendDest = path.join(frontendAssetDir, safeFilename);

      if (!fs.existsSync(backendDest) || !fs.existsSync(frontendDest)) {
        try {
          console.log(`Downloading ${safeFilename} (${entry.seedItem.name} -> ${entry.matched.name})...`);
          const gifRes = await fetch(fullUrl);
          if (gifRes.ok) {
            const buffer = Buffer.from(await gifRes.arrayBuffer());
            fs.writeFileSync(backendDest, buffer);
            fs.writeFileSync(frontendDest, buffer);
            downloadedMap.set(mediaId, safeFilename);
            console.log(`✓ Saved ${safeFilename} (${buffer.length} bytes)`);
          } else {
            console.warn(`✗ HTTP ${gifRes.status} for ${fullUrl}`);
          }
        } catch (err) {
          console.warn(`✗ Failed to download ${safeFilename}: ${err.message}`);
        }
      } else {
        downloadedMap.set(mediaId, safeFilename);
      }
    }
  }

  console.log(`Downloaded ${downloadedMap.size} unique 3D GIFs.`);

  // Write mapping summary to file
  fs.writeFileSync(
    path.resolve(__dirname, 'gif-mapping.json'),
    JSON.stringify(mapping.map(m => ({
      seedName: m.seedItem.name,
      matchedName: m.matched?.name ?? null,
      matchedId: m.matched?.id ?? null,
      gifFile: m.localGifFilename ?? null,
      bodyPart: m.matched?.body_part ?? null,
      target: m.matched?.target ?? null,
      instructions: m.matched?.instruction_steps?.en ?? null,
      secondaryMuscles: m.matched?.secondary_muscles ?? null,
    })), null, 2)
  );

  console.log('Saved gif-mapping.json.');
}

run();
