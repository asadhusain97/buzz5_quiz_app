// Use the v2 imports for onSchedule and logger
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK.
admin.initializeApp();

/**
 * A scheduled Cloud Function (v2) that runs once a week to clean up old rooms
 * in the Realtime Database.
 *
 * It checks each room under /rooms:
 * 1. If roomInfo.deleteAt exists and is in the past, the room is deleted.
 * 2. If roomInfo.deleteAt does NOT exist, the room is deleted.
 */
exports.cleanupOldRooms = onSchedule({
    // This runs the function "at 00:00 on Sunday".
    // You can change this schedule using cron syntax.
    // See: https://cloud.google.com/scheduler/docs/configuring/cron-job-schedules
    schedule: "every sunday 00:00",
    timeZone: "America/Los_Angeles", // Set to your preferred time zone
}, async (event) => {
    // Use logger.log for v2 functions (instead of console.log)
    logger.log("Running weekly room cleanup (v2)...");

    // Get the current time. Timestamps are in milliseconds.
    const now = Date.now();

    // Get a reference to the root of your /rooms data.
    const roomsRef = admin.database().ref("/rooms");

    let roomsDeletedCount = 0;
    const deletionPromises = [];

    try {
        // Fetch all rooms in a single snapshot.
        const snapshot = await roomsRef.once("value");

        if (!snapshot.exists()) {
            logger.log("No rooms found to clean up.");
            return null;
        }

        // Loop through each room (e.g., "2cn6j", "2kwryx")
        snapshot.forEach((roomSnapshot) => {
            const roomCode = roomSnapshot.key;

            // Get the deleteAt timestamp, which is at rooms/{roomCode}/roomInfo/deleteAt
            const deleteAt = roomSnapshot.child("roomInfo/deleteAt").val();

            let shouldDelete = false;

            if (deleteAt === null || deleteAt === undefined) {
                // Condition 2: deleteAt timestamp does not exist.
                logger.log(
                    `Room [${roomCode}]: No deleteAt timestamp. Marking for deletion.`
                );
                shouldDelete = true;
            } else if (deleteAt < now) {
                // Condition 1: deleteAt timestamp is in the past.
                logger.log(
                    `Room [${roomCode}]: deleteAt (${new Date(
                        deleteAt
                    ).toISOString()}) is in the past. Marking for deletion.`
                );
                shouldDelete = true;
            } else {
                // deleteAt is in the future, so we keep the room.
                logger.log(
                    `Room [${roomCode}]: deleteAt (${new Date(
                        deleteAt
                    ).toISOString()}) is in the future. Keeping.`
                );
            }

            if (shouldDelete) {
                // Add the promise to remove the room to our array.
                deletionPromises.push(roomSnapshot.ref.remove());
                roomsDeletedCount++;
            }
        });

        // Wait for all the deletion operations to complete.
        await Promise.all(deletionPromises);

        logger.log(`Cleanup complete. Deleted ${roomsDeletedCount} rooms.`);
        return null;
    } catch (error) {
        logger.error("Error during room cleanup:", error);
        return null;
    }
});