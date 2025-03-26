import { db, collection, getDocs, doc, updateDoc } from "./firebase-config.js";

document.addEventListener("DOMContentLoaded", async () => {
    const classList = document.getElementById("classList");

    if (!classList) {
        console.error("❌ ERROR: Element with ID 'classList' not found in HTML.");
        return;
    }

    // Reference to the parents collection
    const parentsRef = collection(db, "parents");

    // Fetch all parents
    async function fetchParents() {
        classList.innerHTML = ""; // Clears the list before loading new data
        try {
            const querySnapshot = await getDocs(parentsRef);
            querySnapshot.forEach((parentDoc) => {
                const parentId = parentDoc.id;
                
                // Fetch & display children for this parent
                fetchChildren(parentId, parentDoc.data().children); // Pass parent document children data
            });
        } catch (error) {
            console.error("❌ ERROR fetching parents:", error);
        }
    }

    // Fetch children for a specific parent from the parent's 'children' map
    async function fetchChildren(parentId, childrenData) {
        const childrenList = document.getElementById("classList"); // We will append children directly to the same list

        if (!childrenList) return;

        try {
            for (const childKey in childrenData) {
                const childData = childrenData[childKey]; // Access each child object
                const childName = childData.name;  // Get the name of the child
                const classCode = childData.class_code;  // Get the class code from the child data

                // Only display children who have a defined class_code
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

    // Remove class code from child (delete the 'class_code' field)
    window.removeFromClass = async function (parentId, childKey) {
        try {
            const parentDocRef = doc(db, "parents", parentId);

            // Remove the class_code field for the specific child (childKey)
            await updateDoc(parentDocRef, {
                [`children.${childKey}.class_code`]: null  // Use childKey to access the child document's class_code field
            });

            // Refresh the list after removing the class_code
            fetchParents();
        } catch (error) {
            console.error("❌ ERROR removing class code:", error);
        }
    };

    fetchParents();  // Initial call to fetch parents and their children
});
