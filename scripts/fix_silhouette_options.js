/**
 * Fix silhouette question options in Firestore via REST API.
 * Uses the Firebase CLI stored credentials.
 * 
 * Run with: node scripts/fix_silhouette_options.js
 */
const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PROJECT_ID = 'geoquiz-7790d';
const DB_PATH = `projects/${PROJECT_ID}/databases/%28default%29`;
const QUESTIONS_PATH = `${DB_PATH}/documents/questions`;

// Helper: read Firebase CLI credentials
function readFirebaseCreds() {
  const home = process.env.USERPROFILE || process.env.HOME;
  const paths = [
    path.join(home, '.config', 'configstore', 'firebase-tools.json'),
    path.join(home, 'AppData', 'Roaming', 'configstore', 'firebase-tools.json'),
  ];
  for (const p of paths) {
    if (fs.existsSync(p)) {
      return JSON.parse(fs.readFileSync(p, 'utf-8'));
    }
  }
  return null;
}

// Helper: make HTTP request
function request(method, urlStr, body, token) {
  return new Promise((resolve, reject) => {
    const u = new URL(urlStr);
    const options = {
      hostname: u.hostname,
      port: u.port || 443,
      path: u.pathname + u.search,
      method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };
    if (body) options.headers['Content-Length'] = Buffer.byteLength(body);

    const req = https.request(options, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try { resolve(JSON.parse(data)); }
          catch { resolve(data); }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0, 200)}`));
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

// Helper: format value for Firestore REST API
function toFieldValue(v) {
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') {
    if (Number.isInteger(v)) return { integerValue: String(v) };
    return { doubleValue: v };
  }
  if (Array.isArray(v)) {
    return { arrayValue: { values: v.map(toFieldValue) } };
  }
  if (v === null || v === undefined) return { nullValue: 'NULL_VALUE' };
  if (typeof v === 'object') {
    const fields = {};
    for (const [k, val] of Object.entries(v)) {
      fields[k] = toFieldValue(val);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(v) };
}

// Helper: unwrap Firestore field value
function fromFieldValue(v) {
  if (v.stringValue !== undefined) return v.stringValue;
  if (v.integerValue !== undefined) return parseInt(v.integerValue);
  if (v.doubleValue !== undefined) return v.doubleValue;
  if (v.booleanValue !== undefined) return v.booleanValue;
  if (v.arrayValue) {
    return (v.arrayValue.values || []).map(fromFieldValue);
  }
  if (v.mapValue) {
    const obj = {};
    for (const [k, val] of Object.entries(v.mapValue.fields || {})) {
      obj[k] = fromFieldValue(val);
    }
    return obj;
  }
  return null;
}

// Refresh Firebase token
function refreshToken(creds) {
  return new Promise((resolve, reject) => {
    const refreshToken = creds.tokens.refresh_token;
    if (!refreshToken) return reject(new Error('No refresh token'));

    const data = new url.URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    }).toString();

    const req = https.request({
      hostname: 'oauth2.googleapis.com',
      path: '/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(data),
      },
    }, res => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          const result = JSON.parse(body);
          // Update stored credentials
          creds.tokens.access_token = result.access_token;
          creds.tokens.expires_at = Date.now() + (result.expires_in || 3600) * 1000;
          const home = process.env.USERPROFILE || process.env.HOME;
          const p = path.join(home, '.config', 'configstore', 'firebase-tools.json');
          fs.writeFileSync(p, JSON.stringify(creds, null, 2));
          resolve(result.access_token);
        } else {
          reject(new Error(`Refresh failed: ${res.statusCode} - ${body}`));
        }
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function main() {
  console.log('='.repeat(60));
  console.log('  GEO C - Fix Silhouette Options');
  console.log('='.repeat(60));

  // Step 1: Get Firebase token
  console.log('\n1. Getting Firebase token...');
  const creds = readFirebaseCreds();
  if (!creds) {
    console.error('ERROR: Firebase credentials not found. Run firebase login first.');
    process.exit(1);
  }

  let token = creds.tokens.access_token;
  const expiresAt = creds.tokens.expires_at || 0;
  const now = Date.now();
  
  if (expiresAt > now + 60000) {
    console.log('   Token still valid');
  } else {
    console.log('   Token expired, refreshing...');
    try {
      token = await refreshToken(creds);
      console.log('   Token refreshed!');
    } catch (e) {
      console.error('   Token refresh failed:', e.message);
      console.log('   Trying with stored token (may fail)...');
    }
  }

  // Step 2: Extract country names from questions
  console.log('\n2. Extracting country names...');
  const allCountries = new Set();
  
  const queryBody = JSON.stringify({
    structuredQuery: {
      from: [{ collectionId: 'questions' }],
      where: {
        compositeFilter: {
          op: 'OR',
          filters: [
            { fieldFilter: { field: { fieldPath: 'type' }, op: 'EQUAL', value: { stringValue: 'flag' } } },
            { fieldFilter: { field: { fieldPath: 'type' }, op: 'EQUAL', value: { stringValue: 'silhouette' } } },
          ],
        },
      },
      select: { fields: [{ fieldPath: 'correctAnswer' }] },
      limit: 500,
    },
  });

  const queryUrl = `https://firestore.googleapis.com/v1/${DB_PATH}/documents:runQuery`;
  const queryResult = await request('POST', queryUrl, queryBody, token);
  
  queryResult.forEach(item => {
    if (item.document && item.document.fields) {
      const answer = fromFieldValue(item.document.fields.correctAnswer);
      if (answer && answer.length > 2) allCountries.add(answer);
    }
  });
  
  const countries = [...allCountries].sort();
  console.log(`   Found ${countries.length} country names`);

  // Step 3: Query silhouettes from Firestore
  console.log('\n3. Fetching silhouettes from Firestore...');
  
  const silQueryBody = JSON.stringify({
    structuredQuery: {
      from: [{ collectionId: 'questions' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'type' },
          op: 'EQUAL',
          value: { stringValue: 'silhouette' },
        },
      },
      limit: 500,
    },
  });

  const silResult = await request('POST', queryUrl, silQueryBody, token);
  const silhouettes = [];
  
  silResult.forEach(item => {
    if (item.document) {
      const doc = item.document;
      const docId = doc.name.split('/').pop();
      const fields = {};
      for (const [k, v] of Object.entries(doc.fields || {})) {
        fields[k] = fromFieldValue(v);
      }
      silhouettes.push({ id: docId, ...fields });
    }
  });
  
  console.log(`   Found ${silhouettes.length} silhouettes`);

  if (silhouettes.length === 0) {
    console.log('   No silhouettes found!');
    process.exit(0);
  }

  // Step 4: Show sample before
  console.log('\n4. Sample before:');
  silhouettes.slice(0, 3).forEach(s => {
    console.log(`   ${s.id}: correct=${s.correctAnswer}, options=${JSON.stringify(s.options)}`);
  });

  // Step 5: Fix options
  console.log('\n5. Fixing options...');
  
  const countrySet = new Set(countries);
  let nonsenseBefore = 0;
  
  silhouettes.forEach(s => {
    const opts = s.options || [];
    const bad = opts.filter(o => o !== s.correctAnswer && !countrySet.has(o));
    if (bad.length > 0) nonsenseBefore++;
  });
  console.log(`   Nonsense options before: ${nonsenseBefore}/${silhouettes.length}`);

  // Generate new options for each silhouette
  const updates = silhouettes.map(s => {
    const correct = s.correctAnswer;
    if (!correct) return null;

    const available = countries.filter(c => c !== correct);
    if (available.length < 3) {
      console.log(`   WARNING: Not enough countries for ${correct}`);
      return null;
    }

    // Pick 3 random other countries
    const shuffled = [...available].sort(() => Math.random() - 0.5);
    const distractors = shuffled.slice(0, 3);
    const newOptions = [...distractors, correct].sort(() => Math.random() - 0.5);

    return { id: s.id, correctAnswer: correct, options: newOptions };
  }).filter(Boolean);

  console.log(`   Will update ${updates.length} silhouettes`);

  // Step 6: Upload to Firestore using batchWrite
  console.log('\n6. Uploading to Firestore...');
  
  const BATCH_SIZE = 100;
  let uploaded = 0;
  
  for (let i = 0; i < updates.length; i += BATCH_SIZE) {
    const batch = updates.slice(i, i + BATCH_SIZE);
    const writes = batch.map(s => ({
      update: {
        name: `${QUESTIONS_PATH}/${s.id}`,
        fields: {
          options: toFieldValue(s.options),
          correctAnswer: toFieldValue(s.correctAnswer),
        },
      },
    }));

    const batchUrl = `https://firestore.googleapis.com/v1/${DB_PATH}/documents:batchWrite`;
    const result = await request('POST', batchUrl, JSON.stringify({ writes }), token);
    uploaded += batch.length;
    const pct = ((i + batch.length) / updates.length * 100).toFixed(0);
    console.log(`   Batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(updates.length / BATCH_SIZE)} (${pct}%): ${batch.length} updated (total: ${uploaded}/${updates.length})`);
  }

  console.log(`\n7. ✅ Done! ${uploaded}/${updates.length} silhouettes updated.`);

  // Step 8: Verify
  console.log('\n8. Verifying...');
  const verifyResult = await request('POST', queryUrl, silQueryBody, token);
  const verifySilhouettes = [];
  
  verifyResult.forEach(item => {
    if (item.document) {
      const doc = item.document;
      const docId = doc.name.split('/').pop();
      const fields = {};
      for (const [k, v] of Object.entries(doc.fields || {})) {
        fields[k] = fromFieldValue(v);
      }
      verifySilhouettes.push({ id: docId, ...fields });
    }
  });

  let good = 0;
  verifySilhouettes.forEach(s => {
    const opts = s.options || [];
    if (opts.length >= 4) {
      const allValid = opts.every(opt => countrySet.has(opt));
      if (allValid) good++;
    }
  });
  console.log(`   Silhouettes with valid options: ${good}/${verifySilhouettes.length}`);
  
  console.log('\n   Final sample:');
  verifySilhouettes.slice(0, 5).forEach(s => {
    console.log(`   ${s.id}: options=${JSON.stringify(s.options)}`);
  });

  console.log('\n✅ All done!');
}

main().catch(e => {
  console.error('\nFATAL:', e.message);
  process.exit(1);
});
