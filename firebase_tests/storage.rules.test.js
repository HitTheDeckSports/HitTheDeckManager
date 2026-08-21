const fs = require('fs');

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  setDoc,
} = require('firebase/firestore');

const {
  ref,
  uploadBytes,
} = require('firebase/storage');

const projectId = 'demo-hit-the-deck-manager';

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

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(
          context.firestore(),
          'authorized_users',
          'authorized@example.com',
        ),
        {
          active: true,
          role: 'user',
        },
      );
    });

    const unauthenticated = testEnv.unauthenticatedContext();

    const authorized = testEnv.authenticatedContext(
      'authorized-user',
      {
        email: 'authorized@example.com',
        email_verified: true,
      },
    );

    const unauthorized = testEnv.authenticatedContext(
      'unauthorized-user',
      {
        email: 'unauthorized@example.com',
        email_verified: true,
      },
    );

    const image = new Uint8Array([1, 2, 3, 4]);

    await assertFails(
      uploadBytes(
        ref(
          unauthenticated.storage(),
          'inventory/test-item/photo.jpg',
        ),
        image,
        {
          contentType: 'image/jpeg',
        },
      ),
    );

    await assertSucceeds(
      uploadBytes(
        ref(
          authorized.storage(),
          'inventory/test-item/photo.jpg',
        ),
        image,
        {
          contentType: 'image/jpeg',
        },
      ),
    );

    await assertFails(
      uploadBytes(
        ref(
          unauthorized.storage(),
          'inventory/test-item/photo.jpg',
        ),
        image,
        {
          contentType: 'image/jpeg',
        },
      ),
    );

    await assertFails(
      uploadBytes(
        ref(
          authorized.storage(),
          'inventory/test-item/file.txt',
        ),
        image,
        {
          contentType: 'text/plain',
        },
      ),
    );

    const tooLarge = new Uint8Array(
      (5 * 1024 * 1024) + 1,
    );

    await assertFails(
      uploadBytes(
        ref(
          authorized.storage(),
          'inventory/test-item/too-large.jpg',
        ),
        tooLarge,
        {
          contentType: 'image/jpeg',
        },
      ),
    );

    await assertFails(
      uploadBytes(
        ref(
          authorized.storage(),
          'unexpected/path/photo.jpg',
        ),
        image,
        {
          contentType: 'image/jpeg',
        },
      ),
    );

    console.log('Storage security rules tests passed.');
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});