// Firebase configuration for web
const firebaseConfig = {
    apiKey: "AIzaSyCMcCIjIGOgkHYKFAahSq-IG6AMRuwjUJc",
    authDomain: "alchemybioworks-dev.firebaseapp.com",
    projectId: "alchemybioworks-dev",
    storageBucket: "alchemybioworks-dev.firebasestorage.app",
    messagingSenderId: "291308078998",
    appId: "1:291308078998:web:13aaa6f37182fadc7c7fb7"
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
    Phytoplankton: ['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species']
};
