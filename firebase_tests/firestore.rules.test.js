const fs = require('fs');

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} = require('firebase/firestore');

const projectId = 'demo-hit-the-deck-manager';
const rootOwnerEmail = 'sales.hitthedecksports@gmail.com';
const adminEmail = 'admin@example.com';
const secondAdminEmail = 'second-admin@example.com';
const inactiveAdminEmail = 'inactive-admin@example.com';
const legacyUserEmail = 'legacy-user@example.com';
const unauthorizedEmail = 'unauthorized@example.com';

async function seedAccessRecords(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'authorized_users', adminEmail), {
      email: adminEmail,
      active: true,
      role: 'admin',
    });

    await setDoc(doc(db, 'authorized_users', secondAdminEmail), {
      email: secondAdminEmail,
      active: true,
      role: 'admin',
    });

    await setDoc(doc(db, 'authorized_users', inactiveAdminEmail), {
      email: inactiveAdminEmail,
      active: false,
      role: 'admin',
    });

    await setDoc(doc(db, 'authorized_users', legacyUserEmail), {
      email: legacyUserEmail,
      active: true,
      role: 'user',
    });

    await setDoc(doc(db, 'inventory', 'item-1'), {
      inventoryNumber: 'BAT-2608-0001',
      brand: 'Combat',
      status: 'available',
      acquisitionValueCents: 20000,
      askingPriceCents: 30000,
      minimumPriceCents: 25000,
    });
  });
}

function authContext(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, {
    email,
    email_verified: true,
  });
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync('firestore.rules', 'utf8'),
    },
  });

  try {
    await testEnv.clearFirestore();
    await seedAccessRecords(testEnv);

    const unauthenticated = testEnv.unauthenticatedContext();
    const rootOwner = authContext(testEnv, 'root-owner', rootOwnerEmail);
    const admin = authContext(testEnv, 'admin-user', adminEmail);
    const secondAdmin = authContext(
      testEnv,
      'second-admin-user',
      secondAdminEmail,
    );
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

    // Only Owner and active Admin profiles may use application data.
    await assertFails(
      getDoc(doc(unauthenticated.firestore(), 'inventory', 'item-1')),
    );
    await assertFails(
      getDoc(doc(unauthorized.firestore(), 'inventory', 'item-1')),
    );
    await assertFails(
      getDoc(doc(inactiveAdmin.firestore(), 'inventory', 'item-1')),
    );
    await assertFails(
      getDoc(doc(legacyUser.firestore(), 'inventory', 'item-1')),
    );

    await assertSucceeds(
      getDoc(doc(rootOwner.firestore(), 'inventory', 'item-1')),
    );
    await assertSucceeds(
      getDoc(doc(admin.firestore(), 'inventory', 'item-1')),
    );
    await assertSucceeds(
      getDoc(doc(secondAdmin.firestore(), 'inventory', 'item-1')),
    );

    // Owner and Admin both have full operational functionality.
    await assertSucceeds(
      updateDoc(doc(admin.firestore(), 'inventory', 'item-1'), {
        brand: 'Combat Admin Updated',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(admin.firestore(), 'inventory', 'item-1'), {
        status: 'disposed',
      }),
    );

    // Reset status outside rules so later assertions stay independent.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await updateDoc(doc(context.firestore(), 'inventory', 'item-1'), {
        status: 'available',
      });
    });

    // Both Owner and Admin may add additional Admin profiles.
    await assertSucceeds(
      setDoc(doc(admin.firestore(), 'authorized_users', 'new-admin@example.com'), {
        email: 'new-admin@example.com',
        active: true,
        role: 'admin',
      }),
    );
    await assertSucceeds(
      setDoc(doc(rootOwner.firestore(), 'authorized_users', 'owner-added@example.com'), {
        email: 'owner-added@example.com',
        active: true,
        role: 'admin',
      }),
    );

    // Neither role may create a second Owner or a standard User profile.
    await assertFails(
      setDoc(doc(admin.firestore(), 'authorized_users', 'second-owner@example.com'), {
        email: 'second-owner@example.com',
        active: true,
        role: 'owner',
      }),
    );
    await assertFails(
      setDoc(doc(rootOwner.firestore(), 'authorized_users', 'standard-user@example.com'), {
        email: 'standard-user@example.com',
        active: true,
        role: 'user',
      }),
    );
    await assertFails(
      setDoc(doc(admin.firestore(), 'authorized_users', rootOwnerEmail), {
        email: rootOwnerEmail,
        active: true,
        role: 'admin',
      }),
    );

    // Admins may view the access list but cannot change another Admin.
    await assertSucceeds(
      getDoc(doc(admin.firestore(), 'authorized_users', secondAdminEmail)),
    );
    await assertFails(
      updateDoc(doc(admin.firestore(), 'authorized_users', secondAdminEmail), {
        active: false,
      }),
    );
    await assertFails(
      updateDoc(doc(secondAdmin.firestore(), 'authorized_users', adminEmail), {
        active: false,
      }),
    );

    // Only the Owner may disable and restore Admin access.
    await assertSucceeds(
      updateDoc(doc(rootOwner.firestore(), 'authorized_users', secondAdminEmail), {
        active: false,
      }),
    );
    await assertSucceeds(
      updateDoc(doc(rootOwner.firestore(), 'authorized_users', secondAdminEmail), {
        active: true,
      }),
    );

    console.log('Firestore Owner/Admin security rules tests passed.');
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});