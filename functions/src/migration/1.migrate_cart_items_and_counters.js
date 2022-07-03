const firebase = require('firebase-admin');
const { getAllUsersFromAuth, getUsersFromFirestore } = require('../utils/user_utils');

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

migrateCartItems().then((userIds) => {
    console.log(userIds);

    migrateCounters().then((userFromAuthIds) => {
        console.log(userFromAuthIds);
    });
});

async function migrateCartItems() {
    try {
        console.log('Execute migrateCartItems function');

        const userIds = await getUsersFromFirestore(db);
        await updateOrdersCartItems(userIds);

        return userIds;

    } catch (e) {
        console.error(e);
    }
}

async function migrateCounters() {
    try {
        console.log('Execute migrateCounters function');

        const userFromAuthIds = await getAllUsersFromAuth(auth);
        await updateCounters(userFromAuthIds);

        return userFromAuthIds;

    } catch (e) {
        console.error(e);
    }
}

async function updateOrdersCartItems(userIds) {
    console.log('Fetching orders');

    const orders = [];

    await Promise.all(
        userIds.map(async (userId) => {
            console.log('userId ', userId);
            const ordersQuery = await db
                .collection(`users/${userId}/orders`)
                .get();

            ordersQuery.docs.forEach((doc) => {
                if (doc.data()) {
                    console.log(doc.id, '=>', doc.data().cart);
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

    await Promise.all(
        orders.map(async (order) => {
            // console.log(order);
            const ref = db
                .collection(`users/${order.userId}/orders`)
                .doc(order.id);

            console.log('ref ', ref);

            // TODO uncomment to run
            // DEV
            // const result = await ref.update({
            //     cart: order.data.cart.cartItems,
            // });

            // PROD
            // const result = await ref.update({
            //     "cart.cartItems": order.data.cart,
            // });
            // console.log(result);
        }),
    );

    console.log('Update orders successful');
}

async function updateCounters(userIds) {
    console.log('Fetching counters');

    const counts = [];

    await Promise.all(
        userIds.map(async (userId) => {
            console.log('userId ', userId);
            const categoriesQuery = await db
                .collection(`users/${userId}/categories`)
                .get();
            console.log('categoriesCount ', categoriesQuery.docs.length);

            const productsQuery = await db
                .collection(`users/${userId}/products`)
                .get();
            console.log('productsCount ', productsQuery.docs.length);

            const count = {
                userId,
                categoriesCount: categoriesQuery.docs.length,
                productsCount: productsQuery.docs.length,
            };
            counts.push(count);
        }),
    );

    console.log('Updating or creating counters');

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
    //                 categoriesCount: count.categoriesCount,
    //                 productsCount: count.productsCount,
    //             });
    //         } else {
    //             console.log('Create counter: ', count);
    //             await ref.create({
    //                 categoriesCount: count.categoriesCount,
    //                 productsCount: count.productsCount,
    //             });
    //         }
    //     }),
    // );

    console.log('Update counters successful');
}