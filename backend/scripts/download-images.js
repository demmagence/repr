import fs from 'fs';
import path from 'path';
import axios from 'axios';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const targetDir = path.resolve(__dirname, '../public/exercises');
if (!fs.existsSync(targetDir)) {
  fs.mkdirSync(targetDir, { recursive: true });
}

// Map each exercise id to a free-exercise-db image path or direct raw github URL
const exerciseImageMap = {
  "0025": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Bench_Press_-_Medium_Grip/0.jpg",
  "0033": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Incline_Bench_Press_-_Medium_Grip/0.jpg",
  "0289": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Bench_Press/0.jpg",
  "0662": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Pushups/0.jpg",
  "0027": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Deadlift/0.jpg",
  "0022": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bent_Over_Barbell_Row/0.jpg",
  "0652": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Pullups/0.jpg",
  "0261": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Wide-Grip_Lat_Pulldown/0.jpg",
  "0043": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Standing_Military_Press/0.jpg",
  "0334": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Side_Lateral_Raise/0.jpg",
  "0031": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Curl/0.jpg",
  "0241": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Triceps_Pushdown/0.jpg",
  "0047": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Squat/0.jpg",
  "0052": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Romanian_Deadlift/0.jpg",
  "0001": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Sit-Up/0.jpg",
  "0443": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dumbbell_Lunges/0.jpg",
  "0301": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hammer_Curls/0.jpg",
  "0108": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Face_Pull/0.jpg",
  "0585": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Leg_Press/0.jpg",
  "0601": "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Plank/0.jpg",
};

async function downloadImages() {
  console.log(`Starting exercise images download to: ${targetDir}`);
  for (const [id, url] of Object.entries(exerciseImageMap)) {
    const dest = path.join(targetDir, `${id}.jpg`);
    try {
      console.log(`Fetching ${id} from ${url}...`);
      const response = await axios.get(url, { responseType: 'arraybuffer', timeout: 15000 });
      fs.writeFileSync(dest, response.data);
      console.log(`✓ Saved ${id}.jpg (${response.data.length} bytes)`);
    } catch (err) {
      console.warn(`✗ Failed to download ${id} from ${url}: ${err.message}`);
      // Fallback: create a placeholder SVG/JPEG buffer so the file always exists
      const fallbackSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">
        <rect width="400" height="400" fill="#18181b"/>
        <circle cx="200" cy="200" r="80" fill="#27272a"/>
        <text x="200" y="205" font-family="sans-serif" font-size="20" fill="#a1a1aa" text-anchor="middle" dominant-baseline="middle">Exercise ${id}</text>
      </svg>`;
      fs.writeFileSync(path.join(targetDir, `${id}.svg`), fallbackSvg);
    }
  }
  console.log('Download complete.');
}

downloadImages();
