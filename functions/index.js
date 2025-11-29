const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Trigger when a new SOS is created
exports.onSosRequestCreated = functions.firestore
  .document("sos_requests/{sosId}")
  .onCreate(async (snap, context) => {
    const sos = snap.data();
    const sosId = context.params.sosId;
    const db = admin.firestore();

    console.log("New SOS created:", sosId, sos);

    const district = sos.district;
    const bloodGroup = sos.bloodGroup;
    const note = sos.note || "";

    if (!district || !bloodGroup) {
      console.log("Missing district or bloodGroup, skipping.");
      return null;
    }

    // Find matching donors (from users collection because fcmToken is saved there)
    const usersSnap = await db
      .collection("users")
      .where("district", "==", district)
      .where("bloodGroup", "==", bloodGroup)
      .where("isBloodClear", "==", true)
      .get();

    if (usersSnap.empty) {
      console.log("No matching users found for push notifications.");
    }

    console.log(`Found ${usersSnap.size} users for push notifications.`);

    let tokens = [];
    usersSnap.docs.forEach(doc => {
      const user = doc.data();
      if (user.fcmToken) tokens.push(user.fcmToken);
    });

    if (tokens.length > 0) {
      console.log("Sending push to:", tokens.length, "users");

      const payload = {
        notification: {
          title: `🚨 Urgent Blood Need: ${bloodGroup}`,
          body: `Required in ${district}. Tap to view details.`,
        },
        data: {
          sosId,
          district,
          bloodGroup,
          note: note || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        }
      };

      await admin.messaging().sendToDevice(tokens, payload);
      console.log("Push notifications sent.");
    }

    // ===== SMS BATCHING (your original code) =====
    const donorsSnap = await db
      .collection("donors")
      .where("district", "==", district)
      .where("bloodGroup", "==", bloodGroup)
      .where("isBloodClear", "==", true)
      .get();

    if (!donorsSnap.empty) {
      console.log("Preparing pending SMS records...");
      const batch = db.batch();

      donorsSnap.docs.forEach((donorDoc) => {
        const donor = donorDoc.data();
        const phone = donor.phone;
        const donorId = donorDoc.id;

        if (!phone) return;

        const msg =
          `BloodBridge SOS: Need ${bloodGroup} in ${district}. ` +
          (note ? `Note: ${note}. ` : "") +
          `If you can help, open the app.`;

        batch.set(db.collection("pending_sms").doc(), {
          sosId,
          donorId,
          phone,
          message: msg,
          status: "pending",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      console.log("Pending SMS records created.");
    }

    return null;
  });
