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

migrateActive().then((userIds) => {
    // console.log(userIds);
    console.log('End of migration');
});

async function migrateActive() {
    try {
        console.log('Execute migrateActive function');

        const userIds = await getUsersFromFirestore(db);
        await updateCategories(userIds);
        await updateProducts(userIds);
        await updateOrders(userIds);

        return userIds;

    } catch (e) {
        console.error(e);
    }
}

async function updateCategories(userIds) {
    console.log('Fetching categories');

    const categories = [];

    await Promise.all(
        userIds.map(async (userId) => {
            const query = await db
                .collection(`users/${userId}/categories`)
                .get();

            query.docs.forEach((doc) => {
                if (doc.data()) {
                    const category = {
                        id: doc.id,
                        userId,
                        data: doc.data(),
                    };
                    categories.push(category);
                }
            });
        }),
    );

    console.log('Updating categories');

    const updateActive = async (category) => {
        const ref = db
            .collection(`users/${category.userId}/categories`)
            .doc(category.id);

        // TODO uncomment to run
        // const result = await ref.update({
        //     active: true,
        // });
    };
    await Promise.all(
        categories.map(updateActive)
    );

    console.log('Update categories successful');
}

async function updateProducts(userIds) {
    console.log('Fetching products');

    const products = [];

    await Promise.all(
        userIds.map(async (userId) => {
            const query = await db
                .collection(`users/${userId}/products`)
                .get();

            query.docs.forEach((doc) => {
                if (doc.data()) {
                    const product = {
                        id: doc.id,
                        userId,
                        data: doc.data(),
                    };
                    products.push(product);
                }
            });
        }),
    );

    console.log('Updating products');

    const updateActive = async (product) => {
        const ref = db
            .collection(`users/${product.userId}/products`)
            .doc(product.id);

        const categoryToUpdate = !product.data.category ? null : {
            ...product.data.category,
            active: true,
        };

        // TODO uncomment to run
        // const result = await ref.update({
        //     active: true,
        //     category: categoryToUpdate,
        // });
    };
    await Promise.all(
        products.map(updateActive)
    );

    console.log('Update products successful');
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

    const updateActive = async (order) => {
        const ref = db
            .collection(`users/${order.userId}/orders`)
            .doc(order.id);

        const cartItems = order.data.cart.cartItems;
        const cartItemsUpdated = !cartItems ? [] : cartItems.map((cartItem) => {
            const categoryToUpdate = !cartItem.product.category ? null : {
                ...cartItem.product.category,
                active: true,
            };
            const productToUpdate = !cartItem.product ? null : {
                ...cartItem.product,
                category: categoryToUpdate,
                active: true,
            }
            return {
                product: productToUpdate,
                quantity: cartItem.quantity,
            };
        });

        // TODO uncomment to run
        // const result = await ref.update({
        //     cart: {
        //         cartItems: cartItemsUpdated,
        //     },
        // });
    };
    await Promise.all(
        orders.map(updateActive)
    );

    console.log('Update orders successful');
}
