const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

setGlobalOptions({ maxInstances: 5 });

initializeApp();

const db = getFirestore();

exports.recordDistribution = onCall(async (request) => {
  // 1. Require an authenticated user.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must sign in to record a distribution.",
    );
  }

  const uid = request.auth.uid;
  const { itemId, siteId, quantity, assignmentId = null } = request.data || {};

  // 2. Validate the request.
  if (
    typeof itemId !== "string" ||
    !itemId.trim() ||
    typeof siteId !== "string" ||
    !siteId.trim() ||
    !Number.isSafeInteger(quantity) ||
    quantity <= 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid item, site, and positive whole-number quantity are required.",
    );
  }

  if (
    assignmentId !== null &&
    (typeof assignmentId !== "string" || !assignmentId.trim())
  ) {
    throw new HttpsError("invalid-argument", "The assignment ID is invalid.");
  }

  const userRef = db.collection("users").doc(uid);
  const itemRef = db.collection("Inventory").doc(itemId);
  const siteRef = db.collection("Sites").doc(siteId);
  const distributionRef = db.collection("Distributions").doc();

  // 3. Check authorization and update all related data atomically.
  try {
    await db.runTransaction(async (transaction) => {
      const userSnap = await transaction.get(userRef);
      const itemSnap = await transaction.get(itemRef);
      const siteSnap = await transaction.get(siteRef);

      if (!userSnap.exists || userSnap.get("role") !== "ADMIN") {
        throw new HttpsError(
          "permission-denied",
          "Only an administrator can record distributions.",
        );
      }

      if (!itemSnap.exists) {
        throw new HttpsError(
          "not-found",
          "The selected inventory item does not exist.",
        );
      }

      if (!siteSnap.exists) {
        throw new HttpsError("not-found", "The selected site does not exist.");
      }

      const item = itemSnap.data();
      const site = siteSnap.data();
      const availableStock = item.quantity;

      if (!Number.isSafeInteger(availableStock) || availableStock < 0) {
        throw new HttpsError(
          "failed-precondition",
          "The inventory quantity is invalid.",
        );
      }

      if (availableStock < quantity) {
        throw new HttpsError(
          "failed-precondition",
          `Insufficient stock. Available: ${availableStock}.`,
        );
      }

      if (
        typeof item.name !== "string" ||
        typeof item.unit !== "string" ||
        typeof site.name !== "string"
      ) {
        throw new HttpsError(
          "failed-precondition",
          "The inventory or site data is incomplete.",
        );
      }

      // 4. Prepare the history record using trusted server-side data.
      const record = {
        itemId: itemRef.id,
        itemName: item.name,
        siteId: siteRef.id,
        siteName: site.name,
        quantity,
        unit: item.unit,
        volunteerId: uid,
        volunteerName:
          userSnap.get("name") || userSnap.get("email") || "Administrator",
        distributedAt: FieldValue.serverTimestamp(),
      };

      if (assignmentId !== null) {
        record.assignmentId = assignmentId;
      }

      // 5. Both writes commit together.
      transaction.update(itemRef, {
        quantity: availableStock - quantity,
      });

      transaction.set(distributionRef, record);
    });

    return {
      success: true,
      distributionId: distributionRef.id,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }

    console.error("Failed to record distribution:", error);

    throw new HttpsError(
      "internal",
      "Unable to record the distribution. No successful result was confirmed.",
    );
  }
});
