const firebase = require('firebase-admin');
const { getUsersFromFirestore } = require('../utils/user_utils');
const { v4: uuidv4 } = require('uuid');

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

migrateCustomers().then(() => {
    console.log('End of process');
});

async function migrateCustomers() {
    try {
        console.log('Execute migrateCustomers function');
        const userIds = await getUsersFromFirestore(db);
        await createCustomers(userIds);
    } catch (e) {
        console.error(e);
    }
}

async function createCustomers(userIds) {
    console.log('Fetching customers');

    const usersClientIdOrdersMap = {};

    await Promise.all(
        userIds.map(async (userId) => {
            console.log('Deleting existing customers for userId ', userId);
            const customersRef = db
                .collection(`users/${userId}/customers`);
            // TODO uncomment to run
            // await db.recursiveDelete(customersRef);
            console.log('Delete existing customers done');

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
                    usersClientIdOrdersMap[userId] = usersClientIdOrdersMap[userId] || {};
                    usersClientIdOrdersMap[userId][doc.data().clientId] = usersClientIdOrdersMap[userId][doc.data().clientId] || [];
                    usersClientIdOrdersMap[userId][doc.data().clientId].push(order);
                }
            });
        }),
    );

    console.log('Creating customers');

    const createCustomer = async (userId, clientIdOrdersEntry) => {
        const clientId = clientIdOrdersEntry[0];
        const orders = clientIdOrdersEntry[1];
        const userEmail = orders[0].data.userEmail;
        const customerUuid = uuidv4();

        const customer = {
            address: null,
            createdDateTime: firebase.firestore.FieldValue.serverTimestamp(),
            id: null,
            name: clientId,
            nameToUpperCase: clientId.toUpperCase(),
            phoneNumber: null,
            userEmail: userEmail,
            userId: userId,
            uuid: customerUuid,
            active: true,
        };

        const ref = db
            .collection(`users/${userId}/customers`);
        // TODO uncomment to run
        // const result = await ref.add(customer);

        // const documentCreated = await result.get();
        // const customerCreated = documentCreated.data();
        // console.log('customerCreated: ', customerCreated);

        const updateOrderData = {
            customer: customer,
            customerName: clientId,
            customerNameToUpperCase: clientId.toUpperCase(),
            customerUuid: customerUuid,
            // clientId: firebase.firestore.FieldValue.delete(),
        };

        await Promise.all(
            orders.map((order) => {
                updateOrder(userId, order.id, updateOrderData);
            })
        );
    };

    const updateOrder = async (userId, orderId, updateOrderData) => {
        const ref = db
            .collection(`users/${userId}/orders`)
            .doc(orderId);

        // TODO uncomment to run
        // const result = await ref.update(updateOrderData);
    };

    const usersClientIdOrdersEntries = Object.entries(usersClientIdOrdersMap);
    await Promise.all(
        usersClientIdOrdersEntries.map(usersClientIdOrdersEntry => {
            const userId = usersClientIdOrdersEntry[0];
            const clientIdOrdersMap = usersClientIdOrdersEntry[1];
            const clientIdOrdersEntries = Object.entries(clientIdOrdersMap);
            clientIdOrdersEntries.map(clientIdOrdersEntry => createCustomer(userId, clientIdOrdersEntry));
        })
    );

    console.log('Create customers successful');
}
