const https = require('https');
const fs = require('fs');

const API_KEY = 'AIzaSyCFOIzMkKStbRpsM2dtNoLJcTbWp83xe9w';
const PROJECT = 'geoquiz-7790d';
const URL = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/questions?key=${API_KEY}`;

function field(v) {
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(field) } };
  if (v === null) return { nullValue: 'NULL_VALUE' };
  if (typeof v === 'object') return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, val]) => [k, field(val)])) } };
  return { stringValue: String(v) };
}

const questions = JSON.parse(fs.readFileSync('scripts/questions.json', 'utf8'));

function createDoc(index) {
  if (index >= questions.length) {
    console.log(`\n✅ Imported all ${questions.length} questions!`);
    return;
  }
  const q = questions[index];
  const fields = Object.fromEntries(Object.entries(q).map(([k, v]) => [k, field(v)]));
  const body = JSON.stringify({ fields });
  
  const options = { method: 'POST', headers: { 'Content-Type': 'application/json' } };
  const req = https.request(URL, options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      if (res.statusCode === 200) {
        console.log(`✅ [${index + 1}/${questions.length}] ${q.id}`);
      } else {
        console.log(`❌ [${index + 1}/${questions.length}] ${q.id} - Status ${res.statusCode}: ${data.substring(0, 200)}`);
      }
      createDoc(index + 1);
    });
  });
  req.on('error', e => { console.error(`❌ Error on ${q.id}:`, e.message); createDoc(index + 1); });
  req.write(body);
  req.end();
}

console.log(`Importing ${questions.length} questions...`);
createDoc(0);