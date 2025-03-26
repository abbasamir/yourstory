import { db } from "./firebase-config.js";
import { collection, addDoc, deleteDoc, doc, onSnapshot } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

const userList = document.getElementById("userList");


window.addParent = async function() {
    const email = document.getElementById("userEmail").value;
    const role = document.getElementById("userRole").value || "Parent"; 

    if (email.trim() !== "") {
        try {

            await addDoc(collection(db, "parents"), { email, role });
            document.getElementById("userEmail").value = "";  
            console.log("Parent added successfully!");
        } catch (error) {
            console.error("Error adding parent:", error);
            alert("Error adding parent: " + error.message); 
        }
    }
}


window.removeParent = async function(button) {
    const parentId = button.getAttribute("data-id");

    try {

        await deleteDoc(doc(db, "parents", parentId));
        console.log("Parent removed successfully!");
    } catch (error) {
        console.error("Error removing parent:", error);
        alert("Error removing parent: " + error.message); 
    }
}


onSnapshot(collection(db, "parents"), (snapshot) => {
    userList.innerHTML = ""; 

    snapshot.docs.forEach((doc) => {  
        const parent = doc.data();
        const li = document.createElement("li");
        li.innerHTML = `
            ${parent.email} (${parent.role}) 
            <button class="remove-btn" data-id="${doc.id}" onclick="removeParent(this)">Remove</button>
        `;
        userList.appendChild(li);
    });
});
