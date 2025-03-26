import { db } from "./firebase-config.js";
import { collection, addDoc, deleteDoc, doc, onSnapshot } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

const userList = document.getElementById("userList");

// 🔹 Function to add a parent to Firestore
window.addParent = async function() {
    const email = document.getElementById("userEmail").value;
    const role = document.getElementById("userRole").value || "Parent"; // Default role

    if (email.trim() !== "") {
        try {
            // Allow any user to add a parent to the "parents" collection
            await addDoc(collection(db, "parents"), { email, role });
            document.getElementById("userEmail").value = "";  // Clear input after adding
            console.log("Parent added successfully!");
        } catch (error) {
            console.error("Error adding parent:", error);
            alert("Error adding parent: " + error.message); // Alert in case of an error
        }
    }
}

// 🔹 Function to remove a parent from Firestore
window.removeParent = async function(button) {
    const parentId = button.getAttribute("data-id");

    try {
        // Allow any user to remove a parent from the "parents" collection
        await deleteDoc(doc(db, "parents", parentId));
        console.log("Parent removed successfully!");
    } catch (error) {
        console.error("Error removing parent:", error);
        alert("Error removing parent: " + error.message); // Alert in case of an error
    }
}

// 🔹 Listen for real-time updates in Firestore (parents collection)
onSnapshot(collection(db, "parents"), (snapshot) => {
    userList.innerHTML = ""; // Clear list before updating

    snapshot.docs.forEach((doc) => {  // Correctly iterating Firestore documents
        const parent = doc.data();
        const li = document.createElement("li");
        li.innerHTML = `
            ${parent.email} (${parent.role}) 
            <button class="remove-btn" data-id="${doc.id}" onclick="removeParent(this)">Remove</button>
        `;
        userList.appendChild(li);
    });
});
