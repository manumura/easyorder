const functions = require("firebase-functions");
const firebase = require("firebase-admin");

exports.updateProductsCount = (db) => functions.firestore
    .document('users/{userId}/products/{productId}')
    .onWrite(async (change, context) => {

        try {
            console.log('Execute updateProductsCount function');

            const ref = db
                .collection('users')
                .doc(context.params.userId);

            if (!change.before.exists && change.after.exists) {
                // New document Created : add one to count
                await ref.update({productsCount: firebase.firestore.FieldValue.increment(1)});
            } else if (change.before.exists && !change.after.exists) {
                // Deleting document : subtract one from count
                await ref.update({productsCount: firebase.firestore.FieldValue.increment(-1)});
            }

        } catch (e) {
            console.error(e);
        }
    });