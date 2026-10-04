import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const file = path.resolve(__dirname, '../../frontend/lib/data/seed_exercises.dart');
let content = fs.readFileSync(file, 'utf8');

const map = {
  "9Z7KjV4v-B9z8l": "0025",
  "Y9wB5YmR4c6fGg": "0033",
  "X8vC7BnM1s9fLp": "0289",
  "A1bC2dE3fG4hIj": "0662",
  "P4oI5uY6tR7eWq": "0652",
  "Q1wE2rT3yU4iOp": "0261",
  "L7mN8bV9cX2zAs": "0022",
  "K3jH2gF1dE9sAw": "0027",
  "Z9xX8c7v6b5n4m": "0043",
  "M5nB6vC7xZ8lKj": "0334",
  "B2nM3kL4jH5gFd": "0108",
  "H8gF7dS6aP5oIu": "0031",
  "C9vB8nM7lK6jHg": "0301",
  "U7yT6rE5wQ4iOk": "0241",
  "V3bN2mK1lO9pIu": "0047",
  "N7bV8cX9zA1sD2": "0585",
  "D8fG7hJ6kL5mNb": "0443",
  "T6rE5wQ4iO3pLa": "0052",
  "W1eR2tY3uI4oPa": "0001",
  "E4rT5yU6iO7pL8": "0601",
};

for (const [hash, id] of Object.entries(map)) {
  const target = `https://v2.exercisedb.io/image/${hash}`;
  const replacement = `/media/exercises/${id}.jpg`;
  content = content.replace(target, replacement);
}

fs.writeFileSync(file, content, 'utf8');
console.log('Successfully updated seed_exercises.dart!');
