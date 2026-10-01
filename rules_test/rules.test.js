const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'megastore-test-project';

describe('MegaStore Firestore Security Rules', () => {
  let testEnv;

  before(async () => {
    const rulesPath = path.resolve(__dirname, '../firestore.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    if (testEnv) {
      await testEnv.clearFirestore();
    }
  });

  // 1. Role self-escalation denied
  it('denies customer self-escalation to admin on create and update', async () => {
    const customerContext = testEnv.authenticatedContext('user_customer', { email: 'customer@test.com' });
    const customerDb = customerContext.firestore();

    // Trying to create user profile with role: 'admin' must FAIL
    await assertFails(
      customerDb.collection('users').doc('user_customer').set({
        name: 'Attacker',
        email: 'customer@test.com',
        role: 'admin',
        createdAt: new Date().toISOString(),
      })
    );

    // Creating with role: 'customer' must SUCCEED
    await assertSucceeds(
      customerDb.collection('users').doc('user_customer').set({
        name: 'Regular Customer',
        email: 'customer@test.com',
        role: 'customer',
        createdAt: new Date().toISOString(),
      })
    );

    // Trying to update role from 'customer' to 'admin' must FAIL
    await assertFails(
      customerDb.collection('users').doc('user_customer').update({
        role: 'admin',
      })
    );
  });

  // 2. Customer cannot read others' orders
  it('denies customer from reading another customer orders', async () => {
    // Seed an order belonging to user_alice using admin context
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await adminDb.collection('orders').doc('order_alice').set({
        userId: 'user_alice',
        customerName: 'Alice',
        status: 'Pending',
        paymentMethod: 'Cash on Delivery',
        totalAmount: 1200,
      });
    });

    const bobContext = testEnv.authenticatedContext('user_bob', { email: 'bob@test.com' });
    const bobDb = bobContext.firestore();

    // Bob cannot read Alice's order
    await assertFails(bobDb.collection('orders').doc('order_alice').get());

    // Alice can read her own order
    const aliceContext = testEnv.authenticatedContext('user_alice', { email: 'alice@test.com' });
    const aliceDb = aliceContext.firestore();
    await assertSucceeds(aliceDb.collection('orders').doc('order_alice').get());
  });

  // 3. Customer cannot write products
  it('denies customer from writing products, allows public read', async () => {
    const customerContext = testEnv.authenticatedContext('user_customer', { email: 'customer@test.com' });
    const customerDb = customerContext.firestore();

    // Customer cannot create product
    await assertFails(
      customerDb.collection('products').doc('prod_1').set({
        name: 'Sneakers',
        price: 500,
        isDeleted: false,
      })
    );

    // Seed product via rules disabled
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('products').doc('prod_1').set({
        name: 'Sneakers',
        price: 500,
        isDeleted: false,
      });
    });

    // Unauthenticated user can read products
    const unauthDb = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(unauthDb.collection('products').doc('prod_1').get());
  });

  // 4. Invalid order creation denied
  it('denies invalid order creation (e.g. Card payment or non-pending status)', async () => {
    const customerContext = testEnv.authenticatedContext('user_123', { email: 'user@test.com' });
    const customerDb = customerContext.firestore();

    // Invalid: paymentMethod is Card
    await assertFails(
      customerDb.collection('orders').doc('order_invalid_1').set({
        userId: 'user_123',
        status: 'Pending',
        paymentMethod: 'Card',
        totalAmount: 1500,
      })
    );

    // Invalid: status is Delivered
    await assertFails(
      customerDb.collection('orders').doc('order_invalid_2').set({
        userId: 'user_123',
        status: 'Delivered',
        paymentMethod: 'Cash on Delivery',
        totalAmount: 1500,
      })
    );

    // Invalid: wrong userId
    await assertFails(
      customerDb.collection('orders').doc('order_invalid_3').set({
        userId: 'different_user',
        status: 'Pending',
        paymentMethod: 'Cash on Delivery',
        totalAmount: 1500,
      })
    );
  });

  // 5. Valid order creation allowed
  it('allows valid order creation with Cash on Delivery and Pending status', async () => {
    const customerContext = testEnv.authenticatedContext('user_123', { email: 'user@test.com' });
    const customerDb = customerContext.firestore();

    await assertSucceeds(
      customerDb.collection('orders').doc('order_valid').set({
        userId: 'user_123',
        status: 'Pending',
        paymentMethod: 'Cash on Delivery',
        totalAmount: 1500,
        createdAt: new Date().toISOString(),
      })
    );
  });

  // 6. Cancel only when Pending
  it('allows cancellation only when status is Pending', async () => {
    // Seed Pending and Shipped orders
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('orders').doc('order_pending').set({
        userId: 'user_123',
        status: 'Pending',
        paymentMethod: 'Cash on Delivery',
        totalAmount: 2000,
      });
      await db.collection('orders').doc('order_shipped').set({
        userId: 'user_123',
        status: 'Shipped',
        paymentMethod: 'Cash on Delivery',
        totalAmount: 2000,
      });
    });

    const customerContext = testEnv.authenticatedContext('user_123', { email: 'user@test.com' });
    const customerDb = customerContext.firestore();

    // Cancel pending order -> SUCCEEDS
    await assertSucceeds(
      customerDb.collection('orders').doc('order_pending').update({
        status: 'Cancelled',
        updatedAt: new Date().toISOString(),
      })
    );

    // Cancel shipped order -> FAILS
    await assertFails(
      customerDb.collection('orders').doc('order_shipped').update({
        status: 'Cancelled',
        updatedAt: new Date().toISOString(),
      })
    );
  });
});
