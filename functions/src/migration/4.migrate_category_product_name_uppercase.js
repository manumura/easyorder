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

migrateNameToUpperCase().then((userIds) => {
    // console.log(userIds);
    console.log('End of migration');
});

async function migrateNameToUpperCase() {
    try {
        console.log('Execute migrateNameToUpperCase function');

        const userIds = await getUsersFromFirestore(db);
        await updateCategories(userIds);
        await updateProducts(userIds);

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

    const updateName = async (category) => {
        const ref = db
            .collection(`users/${category.userId}/categories`)
            .doc(category.id);

        // TODO uncomment to run
        // const result = await ref.update({
        //     nameToUpperCase: category.data.name.toUpperCase(),
        // });
    };
    await Promise.all(
        categories.map(updateName)
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

    const updateName = async (product) => {
        const ref = db
            .collection(`users/${product.userId}/products`)
            .doc(product.id);

        // TODO uncomment to run
        // const result = await ref.update({
        //     nameToUpperCase: product.data.name.toUpperCase(),
        //     categoryNameToUpperCase: product.data.categoryName ? product.data.categoryName.toUpperCase() : null,
        // });
    };
    await Promise.all(
        products.map(updateName)
    );

    console.log('Update products successful');
}
