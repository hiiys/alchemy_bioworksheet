// Firebase configuration for web
const firebaseConfig = {
    apiKey: "AIzaSyDoTrCljUWhprJ-6CotyBvJmNu10UG__r4",
    authDomain: "macrobenthos-taxonomy-prod.firebaseapp.com",
    projectId: "macrobenthos-taxonomy-prod",
    storageBucket: "macrobenthos-taxonomy-prod.firebasestorage.app",
    messagingSenderId: "369177608730",
    appId: "1:369177608730:web:taxonomy-admin"
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
