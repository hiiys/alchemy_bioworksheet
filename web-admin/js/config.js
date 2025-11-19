// Firebase configuration for web
const firebaseConfig = {
    apiKey: "AIzaSyBIsTfSJrzOs9crnF8ew2MgJg1Xt_FoiWI",
    authDomain: "alchemy-bioworksheet.firebaseapp.com",
    projectId: "alchemy-bioworksheet",
    storageBucket: "alchemy-bioworksheet.firebasestorage.app",
    messagingSenderId: "126522184124",
    appId: "1:126522184124:web:taxonomy-admin"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Get Firebase services
const auth = firebase.auth();
const db = firebase.firestore();

// Rank definitions for each specimen type
const rankDefinitions = {
    Macrobenthos: ['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species'],
    Zooplankton: ['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species'],
    Phytoplankton: ['Division', 'Class', 'Order', 'Family', 'Genus', 'Species']
};
