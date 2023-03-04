async function getUsersFromFirestore(db) {
    console.log('Fetching users from DB');
    try {
        const userIds = [];

        const usersQuery = await db
            .collection('users')
            .get();

        usersQuery.forEach((doc) => {
            userIds.push(doc.id);
        });

        // console.log('users: ', userIds);
        return userIds;
    } catch (e) {
        console.error(e);
        return [];
    }
}

async function getAllUsersFromAuth(auth) {
    console.log('Fetching users from auth');
    try {
        const userIds = [];
        const userRecords = await auth.listUsers();
        userRecords.users.forEach((user) => {
            // console.log(user.toJSON());
            userIds.push(user.uid);
        });

        // console.log('users: ', userIds);
        return userIds;
    } catch (e) {
        console.error(e);
        return [];
    }
}

module.exports = {
    getUsersFromFirestore: getUsersFromFirestore,
    getAllUsersFromAuth: getAllUsersFromAuth,
}