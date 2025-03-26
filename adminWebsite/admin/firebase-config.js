// firebase-config.js
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import { getFirestore, collection, addDoc, getDocs, updateDoc, deleteDoc, doc } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyDzU-whegyvaC7dTkmfkzr5MOu5So9HAFc",
  authDomain: "your-story-43a73.firebaseapp.com",
  databaseURL: "https://your-story-43a73-default-rtdb.firebaseio.com",
  projectId: "your-story-43a73",
  storageBucket: "your-story-43a73.appspot.com",
  messagingSenderId: "918519664641",
  appId: "1:918519664641:web:b7fd0d2b1fd2741fb8f000",
  measurementId: "G-XQH82XFN1F"
};

// 🔹 Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// 🔹 Export Firestore functions
export { db, collection, addDoc, getDocs, updateDoc, deleteDoc, doc };
