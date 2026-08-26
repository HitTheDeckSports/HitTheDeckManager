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
const userEmail = 'user@example.com';
const inactiveEmail = 'inactive@example.com';
const unauthorizedEmail = 'unauthorized@example.com';

async function seedAccessRecords(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'authorized_users', adminEmail), {
      active: true,
      role: 'admin',
    });

    await setDoc(doc(db, 'authorized_users', userEmail), {
      active: true,
      role: 'user',
    });

    await setDoc(doc(db, 'authorized_users', inactiveEmail), {
      active: false,
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

    await setDoc(doc(db, 'sales', 'sale-1'), {
      inventoryItemId: 'item-1',
      salePriceCents: 30000,
      acquisitionValueCents: 20000,
      repairCostCents: 0,
      tradeInCreditCents: 0,
    });

    await setDoc(doc(db, 'repairs', 'repair-1'), {
      inventoryItemId: 'item-1',
      costCents: 2500,
      description: 'Test repair',
    });

    await setDoc(doc(db, 'inventory_financials', 'item-1'), {
      acquisitionValueCents: 20000,
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
    const rootOwner = authContext(
      testEnv,
      'root-owner',
      rootOwnerEmail,
    );
    const admin = authContext(testEnv, 'admin-user', adminEmail);
    const ordinaryUser = authContext(testEnv, 'ordinary-user', userEmail);
    const inactiveUser = authContext(testEnv, 'inactive-user', inactiveEmail);
    const unauthorizedUser = authContext(
      testEnv,
      'unauthorized-user',
      unauthorizedEmail,
    );

    // Authentication and authorization baseline.
    await assertFails(
      getDoc(doc(unauthenticated.firestore(), 'inventory', 'item-1')),
    );
    await assertFails(
      getDoc(doc(unauthorizedUser.firestore(), 'inventory', 'item-1')),
    );
    await assertFails(
      getDoc(doc(inactiveUser.firestore(), 'inventory', 'item-1')),
    );

    await assertSucceeds(
      getDoc(doc(rootOwner.firestore(), 'inventory', 'item-1')),
    );
    await assertSucceeds(
      getDoc(doc(admin.firestore(), 'inventory', 'item-1')),
    );
    await assertSucceeds(
      getDoc(doc(ordinaryUser.firestore(), 'inventory', 'item-1')),
    );

    // Current application collections remain readable to active Users.
    await assertSucceeds(
      getDoc(doc(ordinaryUser.firestore(), 'sales', 'sale-1')),
    );
    await assertSucceeds(
      getDoc(doc(ordinaryUser.firestore(), 'repairs', 'repair-1')),
    );

    // Current ordinary-User inventory updates are allowed when disposal is
    // not involved.
    await assertSucceeds(
      updateDoc(doc(ordinaryUser.firestore(), 'inventory', 'item-1'), {
        brand: 'Combat Updated',
      }),
    );

    // Disposal transitions remain Owner/Admin-only.
    await assertFails(
      updateDoc(doc(ordinaryUser.firestore(), 'inventory', 'item-1'), {
        status: 'disposed',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(admin.firestore(), 'inventory', 'item-1'), {
        status: 'disposed',
      }),
    );

    // Access management remains Owner/Admin-only.
    await assertFails(
      getDoc(doc(ordinaryUser.firestore(), 'authorized_users', adminEmail)),
    );
    await assertSucceeds(
      getDoc(doc(admin.firestore(), 'authorized_users', userEmail)),
    );

    // Future protected financial collections must stay closed until 7B-2
    // deliberately adds Owner/Admin-only rules for them.
    await assertFails(
      getDoc(
        doc(
          ordinaryUser.firestore(),
          'inventory_financials',
          'item-1',
        ),
      ),
    );
    await assertFails(
      getDoc(doc(admin.firestore(), 'inventory_financials', 'item-1')),
    );

    console.log('Firestore security rules baseline tests passed.');
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});