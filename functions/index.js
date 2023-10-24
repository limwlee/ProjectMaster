const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendProjectDeadlineNotification = functions.firestore
  .document("projects/{projectId}")
  .onUpdate(async (change, context) => {
    const projectData = change.after.data();
    const previousProjectData = change.before.data();

    if (projectData.deadline !== previousProjectData.deadline) {
      // Calculate the time remaining until the project deadline
      const deadlineTimestamp = new Date(projectData.deadline.toDate());
      const currentTime = new Date();
      const timeRemaining = deadlineTimestamp - currentTime;

      // If the deadline is 3 days away, send a notification
      if (timeRemaining <= 3 * 24 * 60 * 60 * 1000) {
        const uid = projectData.userId; // Get the user's ID from the project data
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const userToken = userDoc.data().fcmToken; // Get the user's FCM token

        // Send a notification using FCM
        const message = {
          token: userToken,
          notification: {
            title: "Project Deadline Reminder",
            body: "Your project deadline is approaching!",
          },
        };

        await admin.messaging().send(message);
      }
    }
    return null;
  });
