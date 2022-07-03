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

migrateOrders().then((userIds) => {
    // console.log(userIds);
    console.log('End of migration');
});

async function migrateOrders() {
    try {
        console.log('Execute migrateOrders function');

        const userIds = await getUsersFromFirestore(db);
        await updateOrders(userIds);

        return userIds;

    } catch (e) {
        console.error(e);
    }
}

async function updateOrders(userIds) {
    console.log('Fetching orders');

    const ordersWithoutDueDateAndDescription = [];
    const ordersWithoutDueDate = [];
    const ordersWithoutDescription = [];

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

                    if (doc.data().dueDate === undefined && doc.data().description === undefined) {
                        ordersWithoutDueDateAndDescription.push(order);
                    } else if (doc.data().dueDate === undefined) {
                        ordersWithoutDueDate.push(order);
                    } else if (doc.data().description === undefined) {
                        ordersWithoutDescription.push(order);
                    }
                }
            });
        }),
    );

    console.log('Orders without due date and description: ', ordersWithoutDueDateAndDescription
        .map((order) => `userId: ${order.userId} - orderId: ${order.id}`));
    console.log('Orders without due date: ', ordersWithoutDueDate
        .map((order) => `userId: ${order.userId} - orderId: ${order.id}`));
    console.log('Orders without description: ', ordersWithoutDescription
        .map((order) => `userId: ${order.userId} - orderId: ${order.id}`));

    console.log('Updating orders');

    const updateDueDateAndDescription = async (order) => {
        // console.log(order);
        const ref = db
            .collection(`users/${order.userId}/orders`)
            .doc(order.id);

        // TODO uncomment to run
        // const result = await ref.update({
        //     dueDate: null,
        //     description: null,
        // });
    };
    await Promise.all(
        ordersWithoutDueDateAndDescription.map(updateDueDateAndDescription)
    );

    const updateDueDate = async (order) => {
        // console.log(order);
        const ref = db
            .collection(`users/${order.userId}/orders`)
            .doc(order.id);

        // TODO uncomment to run
        // const result = await ref.update({
        //     dueDate: null,
        // });
    };
    await Promise.all(
        ordersWithoutDueDate.map(updateDueDate)
    );

    const updateDescription = async (order) => {
        // console.log(order);
        const ref = db
            .collection(`users/${order.userId}/orders`)
            .doc(order.id);

        // TODO uncomment to run
        // const result = await ref.update({
        //     description: null,
        // });
    };
    await Promise.all(
        ordersWithoutDescription.map(updateDescription)
    );

    console.log('Update orders successful');
}
