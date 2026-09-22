const fs = require('fs');

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const { doc, setDoc } = require('firebase/firestore');
const {
  deleteObject,
  getBytes,
  ref,
  uploadBytes,
} = require('firebase/storage');

const projectId = 'demo-hit-the-deck-manager';

const rootOwnerEmail = 'sales.hitthedecksports@gmail.com';
const adminEmail = 'admin@example.com';
const inactiveAdminEmail = 'inactive-admin@example.com';
const legacyUserEmail = 'legacy-user@example.com';
const unauthorizedEmail = 'unauthorized@example.com';

function authContext(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, {
    email,
    email_verified: true,
  });
}

async function seedAccessRecords(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'authorized_users', adminEmail), {
      email: adminEmail,
      active: true,
      role: 'admin',
    });

    await setDoc(doc(db, 'authorized_users', inactiveAdminEmail), {
      email: inactiveAdminEmail,
      active: false,
      role: 'admin',
    });

    // Simulate a stale pre-Owner/Admin role record.
    await setDoc(doc(db, 'authorized_users', legacyUserEmail), {
      email: legacyUserEmail,
      active: true,
      role: 'user',
    });
  });
}

function imageBytes() {
  return new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync('firestore.rules', 'utf8'),
    },
    storage: {
      rules: fs.readFileSync('storage.rules', 'utf8'),
    },
  });

  try {
    await testEnv.clearFirestore();
    await testEnv.clearStorage();
    await seedAccessRecords(testEnv);

    const unauthenticated = testEnv.unauthenticatedContext();
    const rootOwner = authContext(testEnv, 'root-owner', rootOwnerEmail);
    const admin = authContext(testEnv, 'admin-user', adminEmail);
    const inactiveAdmin = authContext(
      testEnv,
      'inactive-admin-user',
      inactiveAdminEmail,
    );
    const legacyUser = authContext(
      testEnv,
      'legacy-user',
      legacyUserEmail,
    );
    const unauthorized = authContext(
      testEnv,
      'unauthorized-user',
      unauthorizedEmail,
    );

    const ownerPhoto = ref(
      rootOwner.storage(),
      'inventory/item-owner/photo.jpg',
    );

    await assertSucceeds(
      uploadBytes(ownerPhoto, imageBytes(), { contentType: 'image/jpeg' }),
    );

    await assertSucceeds(getBytes(ownerPhoto));
    await assertSucceeds(
      getBytes(
        ref(admin.storage(), 'inventory/item-owner/photo.jpg'),
      ),
    );

    for (const context of [
      unauthenticated,
      unauthorized,
      inactiveAdmin,
      legacyUser,
    ]) {
      await assertFails(
        getBytes(
          ref(context.storage(), 'inventory/item-owner/photo.jpg'),
        ),
      );
    }

    const adminInventoryPhoto = ref(
      admin.storage(),
      'inventory/item-admin/photo.jpg',
    );
    const adminContactPhoto = ref(
      admin.storage(),
      'contacts/contact-admin/photo.jpg',
    );

    await assertSucceeds(
      uploadBytes(adminInventoryPhoto, imageBytes(), {
        contentType: 'image/jpeg',
      }),
    );

    await assertSucceeds(
      uploadBytes(adminContactPhoto, imageBytes(), {
        contentType: 'image/jpeg',
      }),
    );

    await assertFails(
      uploadBytes(
        ref(legacyUser.storage(), 'inventory/legacy/photo.jpg'),
        imageBytes(),
        { contentType: 'image/jpeg' },
      ),
    );

    await assertFails(
      uploadBytes(
        ref(admin.storage(), 'inventory/item-admin/not-image.txt'),
        new Uint8Array([1, 2, 3]),
        { contentType: 'text/plain' },
      ),
    );

    await assertFails(
      uploadBytes(
        ref(admin.storage(), 'inventory/item-admin/too-large.jpg'),
        new Uint8Array(5 * 1024 * 1024 + 1),
        { contentType: 'image/jpeg' },
      ),
    );

    await assertFails(
      uploadBytes(
        ref(admin.storage(), 'other/private.jpg'),
        imageBytes(),
        { contentType: 'image/jpeg' },
      ),
    );

    await assertFails(
      deleteObject(
        ref(legacyUser.storage(), 'inventory/item-admin/photo.jpg'),
      ),
    );

    await assertSucceeds(deleteObject(adminInventoryPhoto));

    console.log('Storage Owner/Admin security rules tests passed.');
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
