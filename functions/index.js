const firebase = require('firebase-admin');
const { updateCategoriesCount } = require("./src/category/updateCategoriesCount.function");
const { updateProductsCount } = require("./src/product/updateProductsCount.function");
const { updateCustomersCount } = require("./src/customer/updateCustomersCount.function");

// https://stackoverflow.com/questions/63578581/firebase-storage-artifacts
// https://github.com/erikch/firebasefunction
// firebase login --interactive
// firebase emulators:start --only functions
// firebase deploy --only functions
// firebase use <project_id> (simple-order-manager-dev)
const storageBucket = 'simple-order-manager-dev.appspot.com';
// const storageBucket = 'simple-order-manager.appspot.com';
const serviceAccountKey = './simple-order-manager-dev-firebase-adminsdk.json';
// const serviceAccountKey = './simple-order-manager-firebase-adminsdk.json';
const databaseUrl = 'https://simple-order-manager-dev.firebaseio.com';
// const databaseUrl = 'https://simple-order-manager.firebaseio.com';

const serviceAccount = require(serviceAccountKey);
firebase.initializeApp({
    credential: firebase.credential.cert(serviceAccount),
    databaseURL: databaseUrl,
    storageBucket: storageBucket
});

// const storage = new Storage({
//     projectId: 'simple-order-manager-dev',
//     keyFilename: serviceAccountKey,
// });

const db = firebase.firestore();

exports.updateCategoriesCount = updateCategoriesCount(db);

exports.updateProductsCount = updateProductsCount(db);

exports.updateCustomersCount = updateCustomersCount(db);

// resize image after upload
// exports.resizeImage = functions.storage.bucket(storageBucket).object().onFinalize(event => {
//     const myBucket = event.bucket;
//     const contentType = event.contentType;
//     const filePath = event.name;
//     console.log('File upload detected, function execution started: ' + filePath);
//
//     if (path.basename(filePath).startsWith('resized-')) {
//         console.log('We already renamed that file!');
//         return false;
//     }
//
//     console.log('bucket: ' + myBucket)
//     // const destBucket = bucket(myBucket);
//     const tmpFilePath = path.join(os.tmpdir(), path.basename(filePath));
//     const metadata = {contentType: contentType};
//     return bucket.file(filePath).download({
//         destination: tmpFilePath
//     }).then(() => {
//         return spawn('convert', [tmpFilePath, '-resize', '500x500', tmpFilePath]);
//     }).then(() => {
//         return bucket.upload(tmpFilePath, {
//             destination: 'images/resized-' + path.basename(filePath),
//             metadata: metadata
//         })
//     });
// });
