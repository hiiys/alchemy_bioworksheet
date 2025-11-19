/**
 * Script to upload test taxonomy data to Firebase Firestore
 *
 * Authentication options:
 * 1. Service Account Key (recommended):
 *    - Go to Firebase Console > Project Settings > Service Accounts
 *    - Click "Generate new private key"
 *    - Save the JSON file
 *    - Set environment variable: GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json
 *    - Run: node upload_test_data.js
 *
 * 2. gcloud CLI (if installed):
 *    - Run: gcloud auth application-default login
 *    - Then: node upload_test_data.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const path = require('path');

// Check for service account key in common locations
const keyLocations = [
  process.env.GOOGLE_APPLICATION_CREDENTIALS,
  path.join(__dirname, 'service-account-key.json'),
  path.join(__dirname, '..', 'service-account-key.json'),
];

let serviceAccount = null;
for (const loc of keyLocations) {
  if (loc && fs.existsSync(loc)) {
    console.log(`Using service account key from: ${loc}`);
    serviceAccount = require(loc);
    break;
  }
}

// Initialize Firebase Admin
if (serviceAccount) {
  initializeApp({
    credential: cert(serviceAccount),
    projectId: 'macrobenthos-taxonomy-prod',
  });
} else {
  console.log('No service account key found. Using Application Default Credentials.');
  console.log('If this fails, please download a service account key from Firebase Console.');
  console.log('');
  initializeApp({
    projectId: 'macrobenthos-taxonomy-prod',
  });
}

const db = getFirestore();

// Test taxonomy data for each specimen type
// NOTE: IDs must be globally unique across all specimen types
const testData = {
  Macrobenthos: {
    ranks: [
      { name: 'Phylum', sequence: 1 },
      { name: 'Class', sequence: 2 },
      { name: 'Order', sequence: 3 },
      { name: 'Family', sequence: 4 },
      { name: 'Genus', sequence: 5 },
      { name: 'Species', sequence: 6 },
    ],
    taxa: [
      // Phylum level (IDs 1-99)
      { id: 1, parentId: null, name: 'Annelida', rank: 'Phylum', notes: 'Segmented worms' },
      { id: 2, parentId: null, name: 'Arthropoda', rank: 'Phylum', notes: 'Jointed-legged invertebrates' },
      { id: 3, parentId: null, name: 'Mollusca', rank: 'Phylum', notes: 'Soft-bodied invertebrates' },

      // Class level - Annelida
      { id: 10, parentId: 1, name: 'Polychaeta', rank: 'Class', notes: 'Marine bristle worms' },
      { id: 11, parentId: 1, name: 'Oligochaeta', rank: 'Class', notes: 'Earthworms and relatives' },

      // Class level - Arthropoda
      { id: 20, parentId: 2, name: 'Malacostraca', rank: 'Class', notes: 'Crabs, shrimp, etc.' },
      { id: 21, parentId: 2, name: 'Insecta', rank: 'Class', notes: 'Insects' },

      // Class level - Mollusca
      { id: 30, parentId: 3, name: 'Gastropoda', rank: 'Class', notes: 'Snails and slugs' },
      { id: 31, parentId: 3, name: 'Bivalvia', rank: 'Class', notes: 'Clams, mussels, oysters' },

      // Order level - Polychaeta
      { id: 100, parentId: 10, name: 'Eunicida', rank: 'Order', notes: null },
      { id: 101, parentId: 10, name: 'Phyllodocida', rank: 'Order', notes: null },

      // Order level - Malacostraca
      { id: 200, parentId: 20, name: 'Decapoda', rank: 'Order', notes: 'Crabs, shrimp, lobsters' },
      { id: 201, parentId: 20, name: 'Amphipoda', rank: 'Order', notes: 'Scuds' },

      // Family level - Decapoda
      { id: 2000, parentId: 200, name: 'Penaeidae', rank: 'Family', notes: 'Penaeid shrimp' },
      { id: 2001, parentId: 200, name: 'Portunidae', rank: 'Family', notes: 'Swimming crabs' },

      // Genus level
      { id: 20000, parentId: 2000, name: 'Penaeus', rank: 'Genus', notes: null },
      { id: 20010, parentId: 2001, name: 'Portunus', rank: 'Genus', notes: null },

      // Species level
      { id: 200000, parentId: 20000, name: 'Penaeus monodon', rank: 'Species', notes: 'Giant tiger prawn' },
      { id: 200001, parentId: 20000, name: 'Penaeus vannamei', rank: 'Species', notes: 'Whiteleg shrimp' },
      { id: 200100, parentId: 20010, name: 'Portunus pelagicus', rank: 'Species', notes: 'Blue swimming crab' },
    ],
  },

  Zooplankton: {
    ranks: [
      { name: 'Phylum', sequence: 1 },
      { name: 'Class', sequence: 2 },
      { name: 'Order', sequence: 3 },
      { name: 'Family', sequence: 4 },
      { name: 'Genus', sequence: 5 },
      { name: 'Species', sequence: 6 },
    ],
    taxa: [
      // Phylum level (IDs 1000001+)
      { id: 1000001, parentId: null, name: 'Arthropoda', rank: 'Phylum', notes: 'Jointed-legged invertebrates' },
      { id: 1000002, parentId: null, name: 'Rotifera', rank: 'Phylum', notes: 'Wheel animals' },

      // Class level - Arthropoda
      { id: 1000010, parentId: 1000001, name: 'Copepoda', rank: 'Class', notes: 'Copepods' },
      { id: 1000011, parentId: 1000001, name: 'Branchiopoda', rank: 'Class', notes: 'Water fleas' },

      // Class level - Rotifera
      { id: 1000020, parentId: 1000002, name: 'Monogononta', rank: 'Class', notes: 'Most common rotifers' },

      // Order level
      { id: 1000100, parentId: 1000010, name: 'Calanoida', rank: 'Order', notes: 'Calanoid copepods' },
      { id: 1000101, parentId: 1000010, name: 'Cyclopoida', rank: 'Order', notes: 'Cyclopoid copepods' },
      { id: 1000110, parentId: 1000011, name: 'Cladocera', rank: 'Order', notes: 'Water fleas' },

      // Family level
      { id: 1001000, parentId: 1000100, name: 'Calanidae', rank: 'Family', notes: null },
      { id: 1001100, parentId: 1000110, name: 'Daphniidae', rank: 'Family', notes: 'Daphnia family' },

      // Genus level
      { id: 1010000, parentId: 1001000, name: 'Calanus', rank: 'Genus', notes: null },
      { id: 1011000, parentId: 1001100, name: 'Daphnia', rank: 'Genus', notes: null },

      // Species level
      { id: 1100000, parentId: 1010000, name: 'Calanus finmarchicus', rank: 'Species', notes: 'Common copepod' },
      { id: 1110000, parentId: 1011000, name: 'Daphnia magna', rank: 'Species', notes: 'Common water flea' },
    ],
  },

  Phytoplankton: {
    ranks: [
      { name: 'Division', sequence: 1 },
      { name: 'Class', sequence: 2 },
      { name: 'Order', sequence: 3 },
      { name: 'Family', sequence: 4 },
      { name: 'Genus', sequence: 5 },
      { name: 'Species', sequence: 6 },
    ],
    taxa: [
      // Division level (IDs 2000001+)
      { id: 2000001, parentId: null, name: 'Bacillariophyta', rank: 'Division', notes: 'Diatoms' },
      { id: 2000002, parentId: null, name: 'Dinoflagellata', rank: 'Division', notes: 'Dinoflagellates' },
      { id: 2000003, parentId: null, name: 'Chlorophyta', rank: 'Division', notes: 'Green algae' },

      // Class level - Bacillariophyta
      { id: 2000010, parentId: 2000001, name: 'Bacillariophyceae', rank: 'Class', notes: 'Pennate diatoms' },
      { id: 2000011, parentId: 2000001, name: 'Coscinodiscophyceae', rank: 'Class', notes: 'Centric diatoms' },

      // Class level - Dinoflagellata
      { id: 2000020, parentId: 2000002, name: 'Dinophyceae', rank: 'Class', notes: 'True dinoflagellates' },

      // Order level
      { id: 2000100, parentId: 2000010, name: 'Naviculales', rank: 'Order', notes: null },
      { id: 2000110, parentId: 2000011, name: 'Coscinodiscales', rank: 'Order', notes: null },
      { id: 2000200, parentId: 2000020, name: 'Peridiniales', rank: 'Order', notes: null },

      // Family level
      { id: 2001000, parentId: 2000100, name: 'Naviculaceae', rank: 'Family', notes: null },
      { id: 2001100, parentId: 2000110, name: 'Coscinodiscaceae', rank: 'Family', notes: null },

      // Genus level
      { id: 2010000, parentId: 2001000, name: 'Navicula', rank: 'Genus', notes: null },
      { id: 2011000, parentId: 2001100, name: 'Coscinodiscus', rank: 'Genus', notes: null },

      // Species level
      { id: 2100000, parentId: 2010000, name: 'Navicula radiosa', rank: 'Species', notes: null },
      { id: 2110000, parentId: 2011000, name: 'Coscinodiscus granii', rank: 'Species', notes: null },
    ],
  },
};

async function uploadData() {
  console.log('Starting data upload to Firebase...\n');

  for (const [specimenType, data] of Object.entries(testData)) {
    console.log(`Uploading ${specimenType}...`);

    const taxonomyRef = db.collection('taxonomies').doc(specimenType);

    // Delete existing taxa first
    const taxaRef = taxonomyRef.collection('taxa');
    const existingTaxa = await taxaRef.get();
    if (!existingTaxa.empty) {
      console.log(`  - Deleting ${existingTaxa.size} existing taxa...`);
      const batch = db.batch();
      existingTaxa.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
    }

    // Delete existing rank definitions
    const ranksRef = taxonomyRef.collection('rankDefinitions');
    const existingRanks = await ranksRef.get();
    if (!existingRanks.empty) {
      const batch = db.batch();
      existingRanks.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
    }

    // Set metadata
    await taxonomyRef.set({
      lastModified: new Date(),
      modifiedBy: 'test-script',
      taxaCount: data.taxa.length,
    });

    // Upload rank definitions
    for (const rank of data.ranks) {
      await ranksRef.doc(rank.sequence.toString()).set({
        specimenType: specimenType,
        name: rank.name,
        sequence: rank.sequence,
      });
    }
    console.log(`  - Uploaded ${data.ranks.length} rank definitions`);

    // Upload taxa
    for (const taxon of data.taxa) {
      await taxaRef.doc(taxon.id.toString()).set({
        parentId: taxon.parentId,
        name: taxon.name,
        rank: taxon.rank,
        notes: taxon.notes,
        specimenType: specimenType,
      });
    }
    console.log(`  - Uploaded ${data.taxa.length} taxa`);
  }

  console.log('\nData upload completed successfully!');
  console.log('You can now sync this data to the mobile app.');
}

uploadData().catch(console.error);
