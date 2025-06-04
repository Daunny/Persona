const fs = require('fs');
const path = require('path');
const filePath = path.join(__dirname, '..', 'app.tsx');
const content = fs.readFileSync(filePath, 'utf8');
const questionRegex = /id: 'q(\d+)'[^\n]*\n(?:[^\n]*\n)*?options: \[/g;
const optionRegex = /{ id: 'q\d+o\d+'[^}]*}/g;
let match;
const ids = [];
let allValid = true;
while ((match = questionRegex.exec(content)) !== null) {
  const questionBlock = match[0];
  const idMatch = questionBlock.match(/id: 'q(\d+)'/);
  const id = idMatch ? idMatch[1] : null;
  if (id) ids.push(id);
  const options = questionBlock.match(optionRegex) || [];
  if (options.length !== 5) {
    console.error(`Question q${id} has ${options.length} options`);
    allValid = false;
  }
}
const duplicates = ids.filter((id, i) => ids.indexOf(id) !== i);
if (duplicates.length) {
  console.error('Duplicate question IDs:', [...new Set(duplicates)].join(', '));
  allValid = false;
}
if (allValid) {
  console.log('All questions validated successfully.');
  process.exit(0);
} else {
  process.exit(1);
}
