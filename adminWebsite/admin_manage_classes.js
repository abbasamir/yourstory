import { db, collection, getDocs, doc, updateDoc } from "./firebase-config.js";

document.addEventListener("DOMContentLoaded", async () => {
    const classList = document.getElementById("classList");

    if (!classList) {
        console.error("❌ ERROR: Element with ID 'classList' not found in HTML.");
        return;
    }


    const parentsRef = collection(db, "parents");


    async function fetchParents() {
        classList.innerHTML = ""; 
        try {
            const querySnapshot = await getDocs(parentsRef);
            querySnapshot.forEach((parentDoc) => {
                const parentId = parentDoc.id;
                
               
                fetchChildren(parentId, parentDoc.data().children); 
            });
        } catch (error) {
            console.error("❌ ERROR fetching parents:", error);
        }
    }


    async function fetchChildren(parentId, childrenData) {
        const childrenList = document.getElementById("classList"); 

        if (!childrenList) return;

        try {
            for (const childKey in childrenData) {
                const childData = childrenData[childKey]; 
                const childName = childData.name;  
                const classCode = childData.class_code;  

                
                if (classCode) {
                    const li = document.createElement("li");

                    li.innerHTML = `${childName} (Class Code: ${classCode})
                        <button onclick="removeFromClass('${parentId}', '${childKey}')">Remove from Class</button>`;

                    childrenList.appendChild(li);
                }
            }
        } catch (error) {
            console.error("❌ ERROR fetching children:", error);
        }
    }

  
    window.removeFromClass = async function (parentId, childKey) {
        try {
            const parentDocRef = doc(db, "parents", parentId);

            
            await updateDoc(parentDocRef, {
                [`children.${childKey}.class_code`]: null  
            });

            
            fetchParents();
        } catch (error) {
            console.error("❌ ERROR removing class code:", error);
        }
    };

    fetchParents();  
});
