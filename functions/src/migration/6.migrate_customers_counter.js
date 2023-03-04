const firebase = require('firebase-admin');
const { getAllUsersFromAuth } = require('../utils/user_utils');

const storageBucket = 'simple-order-manager-dev.appspot.com';
// const storageBucket = 'simple-order-manager.appspot.com';
const serviceAccountKey = '../../simple-order-manager-dev-firebase-adminsdk.json';
// const serviceAccountKey = '../../simple-order-manager-firebase-adminsdk.json';
const databaseUrl = 'https://simple-order-manager-dev.firebaseio.com';
// const databaseUrl = 'https://simple-order-manager.firebaseio.com';

const serviceAccount = require(serviceAccountKey);
firebase.initializeApp({
    credential: firebase.credential.cert(serviceAccount),
    databaseURL: databaseUrl,
    storageBucket: storageBucket
});

const db = firebase.firestore();
const auth = firebase.auth();

migrateCounter().then((userFromAuthIds) => {
    console.log(userFromAuthIds);
});

async function migrateCounter() {
    try {
        console.log('Execute migrateCounter function');

        const userFromAuthIds = await getAllUsersFromAuth(auth);
        await updateCounter(userFromAuthIds);

        return userFromAuthIds;

    } catch (e) {
        console.error(e);
    }
}

async function updateCounter(userIds) {
    console.log('Fetching counter');

    const counts = [];

    await Promise.all(
        userIds.map(async (userId) => {
            console.log('userId ', userId);
            const customersQuery = await db
                .collection(`users/${userId}/customers`)
                .get();
            console.log('customersCount ', customersQuery.docs.length);

            const count = {
                userId,
                customersCount: customersQuery.docs.length,
            };
            counts.push(count);
        }),
    );

    console.log('Updating or creating counter');

    // TODO uncomment to run
    // await Promise.all(
    //     counts.map(async (count) => {
    //         const ref = db
    //             .collection(`users`)
    //             .doc(count.userId);
    //
    //         const snapshot = await ref.get();
    //         if (snapshot.exists) {
    //             console.log('Update counter: ', count);
    //             await ref.update({
    //                 customersCount: count.customersCount,
    //             });
    //         } else {
    //             console.log('Create counter: ', count);
    //             await ref.create({
    //                 customersCount: count.customersCount,
    //             });
    //         }
    //     }),
    // );

    console.log('Update counter successful');
}