/**
 * Fix silhouette question options in Firestore.
 * Run with: node functions/fix_silhouettes.js
 */
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Try to initialize with application default credentials
// The Firebase CLI may have stored credentials that work
process.env.GOOGLE_APPLICATION_CREDENTIALS = '';

try {
  admin.initializeApp({
    projectId: 'geoquiz-7790d',
    credential: admin.credential.applicationDefault(),
  });
} catch (e) {
  console.error('Failed to initialize with ADC:', e.message);
  process.exit(1);
}

const db = admin.firestore();
const silhouettesCol = db.collection('questions');

async function main() {
  console.log('='.repeat(60));
  console.log('  GEO C - Fix Silhouette Options (Node.js)');
  console.log('='.repeat(60));

  // Step 1: Extract all country names from flag questions
  console.log('\n1. Extracting country names from questions...');
  const allCountries = new Set();
  const allQuestionsSnapshot = await silhouettesCol.get();
  allQuestionsSnapshot.forEach(doc => {
    const data = doc.data();
    if (data.type === 'flag' || data.type === 'silhouette') {
      const answer = data.correctAnswer || '';
      if (answer.length > 2) {
        allCountries.add(answer);
      }
    }
  });
  
  const countries = [...allCountries].sort();
  console.log(`   Found ${countries.length} country names`);

  // Step 2: Query silhouette questions
  console.log('\n2. Fetching silhouettes from Firestore...');
  const snapshot = await silhouettesCol
    .where('type', '==', 'silhouette')
    .get();
  
  const silhouettes = [];
  snapshot.forEach(doc => {
    silhouettes.push({ id: doc.id, ...doc.data() });
  });
  console.log(`   Found ${silhouettes.length} silhouettes in Firestore`);

  if (silhouettes.length === 0) {
    console.log('   No silhouettes found!');
    process.exit(0);
  }

  // Step 3: Show sample before
  console.log('\n3. Sample before fix:');
  silhouettes.slice(0, 3).forEach(s => {
    console.log(`   ${s.id}: correct=${s.correctAnswer}, options=${JSON.stringify(s.options || [])}`);
  });

  // Step 4: Generate nonsense count
  let nonsenseCount = 0;
  const countrySet = new Set(countries);
  silhouettes.forEach(s => {
    const options = s.options || [];
    const nonCountryOptions = options.filter(opt => opt !== s.correctAnswer && !countrySet.has(opt));
    if (nonCountryOptions.length > 0) {
      nonsenseCount++;
    }
  });
  console.log(`\n4. Silhouettes with non-country options: ${nonsenseCount}/${silhouettes.length}`);

  // Step 5: Fix options
  console.log('\n5. Fixing options...');
  const batch = db.batch();
  let fixedCount = 0;
  let errorCount = 0;

  silhouettes.forEach(s => {
    const correct = s.correctAnswer;
    if (!correct) return;

    // Pick 3 random countries that are not the correct answer
    const available = countries.filter(c => c !== correct);
    if (available.length < 3) {
      console.log(`   WARNING: Not enough countries for ${correct}`);
      errorCount++;
      return;
    }

    // Shuffle and pick 3
    const shuffled = [...available].sort(() => Math.random() - 0.5);
    const distractors = shuffled.slice(0, 3);
    
    const newOptions = [...distractors, correct];
    // Shuffle options
    newOptions.sort(() => Math.random() - 0.5);

    const docRef = silhouettesCol.doc(s.id);
    batch.update(docRef, { options: newOptions });
    fixedCount++;
  });

  // Step 6: Commit batch
  console.log(`   Fixed: ${fixedCount}, Errors: ${errorCount}`);

  if (fixedCount > 0) {
    await batch.commit();
    console.log(`\n6. ✅ Batch committed! ${fixedCount} silhouettes updated.`);
  } else {
    console.log('\n6. Nothing to update.');
  }

  // Step 7: Verify
  console.log('\n7. Verifying...');
  const verifySnapshot = await silhouettesCol
    .where('type', '==', 'silhouette')
    .get();
  
  const verifySilhouettes = [];
  verifySnapshot.forEach(doc => {
    verifySilhouettes.push({ id: doc.id, ...doc.data() });
  });

  let good = 0;
  verifySilhouettes.forEach(s => {
    const opts = s.options || [];
    if (opts.length === 4) {
      const allValid = opts.every(opt => countrySet.has(opt));
      if (allValid) good++;
    }
  });
  console.log(`   Silhouettes with 4 country-only options: ${good}/${verifySilhouettes.length}`);

  console.log('\n   Sample after:');
  verifySilhouettes.slice(0, 5).forEach(s => {
    console.log(`   ${s.id}: options=${JSON.stringify(s.options)}`);
  });

  console.log('\nDone!');
}

main().catch(console.error);
