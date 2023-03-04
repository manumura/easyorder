const functions = require("firebase-functions");
const firebase = require("firebase-admin");

exports.updateCustomersCount = (db) => functions.firestore
    .document('users/{userId}/customers/{customerId}')
    .onWrite(async (change, context) => {

        try {
            console.log('Execute updateCustomersCount function');

            const ref = db
                .collection('users')
                .doc(context.params.userId);

            if (!change.before.exists && change.after.exists) {
                // New document Created : add one to count
                await ref.update({customersCount: firebase.firestore.FieldValue.increment(1)});
            } else if (change.before.exists && !change.after.exists) {
                // Deleting document : subtract one from count
                await ref.update({customersCount: firebase.firestore.FieldValue.increment(-1)});
            }

        } catch (e) {
            console.error(e);
        }
    });