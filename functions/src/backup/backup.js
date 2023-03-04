const os = require('os');
const path = require('path');
const fsAsync = require('fs').promises;
const firebase = require('firebase-admin');
const moment = require('moment');
const firestoreBackUp = require('firestore-export-import');

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
// https://firebaseopensource.com/projects/dalenguyen/firestore-backup-restore/
firestoreBackUp.initializeApp(serviceAccount);

const storage = firebase.storage();

backUp().then((backUp) => {
    console.log(backUp);
});

async function backUp() {
    try {
        console.log('Back up data');

        const backUp = await firestoreBackUp
            .backup('users');

        await uploadBackUpToBucket(backUp);

        return backUp;
    } catch (e) {
        console.log(e);
    }
}

async function uploadBackUpToBucket(backUp) {

    try {
        const nowAsString = moment().utc().format('YYYYMMDDHHmmss');
        const fileName = `backup-${nowAsString}.json`;
        const destination = 'backup/' + fileName;

        const tempFilePath = path.join(os.tmpdir(), fileName);
        console.log( `Writing out to ${tempFilePath}` );
        await writeFileToLocalPath(tempFilePath, JSON.stringify(backUp));

        await storage
            .bucket()
            .upload( tempFilePath, { destination } );

        console.log('Upload successful');
        // await deleteFileFromLocalPath(tempFilePath);

    } catch (e) {
        console.error(e);
    }
}

async function retrieveBackUp() {
    try {
        console.log('Fetching backups');

        const filesResponse = await storage
            .bucket()
            .getFiles({
                directory: 'backup',
            });

        const fileNames = [];
        filesResponse.map((files) => {
            files.map((file) => {
                fileNames.push(file.name);
            });
        });

        const urls = [];
        await Promise.all(
            fileNames.map(async (fileName) => {
                const remoteFile = storage.bucket().file(fileName);
                const expiresAsDate = moment().add(1, 'hours').toDate();
                const signedUrls = await remoteFile.getSignedUrl({
                        action: 'read',
                        expires: expiresAsDate}
                    );
                const signedUrl = signedUrls[0];
                urls.push({
                    name: fileName,
                    url: signedUrl,
                });
            }),
        );

        console.log(urls);

        // Download backups
        await Promise.all(
            urls.map(async (url) => {
                const baseName = path.basename(url.name);
                const tempFilePath = path.join(os.tmpdir(), baseName);

                await storage
                    .bucket()
                    .file(urls[0].name)
                    .download({destination: tempFilePath});
                console.log('File downloaded to ', tempFilePath);
            }),
        );

        return urls;

    } catch (e) {
        console.error(e);
    }
}

async function writeFileToLocalPath(filePath, data) {
    try {
        await fsAsync.writeFile(filePath, data);
        console.log(`File created successfully ${filePath}`);
    } catch (e) {
        console.error(`Error while creating file ${filePath}: ${e}`);
    }
}

async function deleteFileFromLocalPath(filePath) {
    try {
        await fsAsync.unlink(filePath);
        console.log(`File deleted successfully ${filePath}`);
    } catch (e) {
        console.error(`Error while deleting file ${filePath}: ${e}`);
    }
}
