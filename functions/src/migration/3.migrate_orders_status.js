const firebase = require('firebase-admin');
const { getUsersFromFirestore } = require('../utils/user_utils');

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

migrateOrdersStatus().then((userIds) => {
    // console.log(userIds);
    console.log('End of migration');
});

async function migrateOrdersStatus() {
    try {
        console.log('Execute migrateOrdersStatus function');

        const userIds = await getUsersFromFirestore(db);
        await updateOrders(userIds);

        return userIds;

    } catch (e) {
        console.error(e);
    }
}

async function updateOrders(userIds) {
    console.log('Fetching orders');

    const orders = [];

    await Promise.all(
        userIds.map(async (userId) => {
            // console.log('userId ', userId);
            const ordersQuery = await db
                .collection(`users/${userId}/orders`)
                .get();

            ordersQuery.docs.forEach((doc) => {
                if (doc.data()) {
                    const order = {
                        id: doc.id,
                        userId,
                        data: doc.data(),
                    };
                    orders.push(order);
                }
            });
        }),
    );

    console.log('Updating orders');

    const updateStatus = async (order) => {
        // console.log(order);
        const ref = db
            .collection(`users/${order.userId}/orders`)
            .doc(order.id);

        // TODO uncomment to run
        // const result = await ref.update({
        //     status: order.data.completed ? 'completed' : 'pending',
        // });
    };
    await Promise.all(
        orders.map(updateStatus)
    );

    console.log('Update orders successful');
}
