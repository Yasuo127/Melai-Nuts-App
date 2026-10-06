// Firestore rules tests. Run:  cd firestore-tests && npm install && npm test
// (needs Java; downloads the Firestore emulator on first run).
// NOTE: written alongside the rules but NOT executed in the authoring sandbox
// (emulator download was blocked) — run them before deploying.
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp } = require('firebase/firestore');
const { readFileSync } = require('node:fs');
const { test, before, after, beforeEach } = require('node:test');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-melai',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());

const profile = (role, extra = {}) => ({
  email: `${role}@x.com`, name: role, role, phone: null, branch: null,
  isActive: true, createdAt: new Date(), ...extra,
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/owner1'), profile('owner'));
    await setDoc(doc(db, 'users/staffA'), profile('staff', { branch: 'Calamba Branch' }));
    await setDoc(doc(db, 'users/staffOff'), profile('staff', { branch: 'Calamba Branch', isActive: false }));
    await setDoc(doc(db, 'users/rider1'), profile('delivery', { branch: 'Calamba Branch' }));
    await setDoc(doc(db, 'users/cust1'), profile('customer'));
    await setDoc(doc(db, 'users/cust2'), profile('customer'));
    await setDoc(doc(db, 'products/p1'), { name: 'Cashew', price: 100 });
    await setDoc(doc(db, 'inventory/b1'), { branch: 'Calamba Branch', quantity: 10, productId: 'p1' });
    await setDoc(doc(db, 'inventory/b2'), { branch: 'Los Baños Hub', quantity: 10, productId: 'p1' });
    await setDoc(doc(db, 'orders/o1'), { customerId: 'cust1', branch: 'Calamba Branch', status: 'pending', riderId: 'rider1', total: 100 });
  });
});
const as = (uid, email) => env.authenticatedContext(uid, email ? { email } : {}).firestore();
// A user whose email Firebase has verified (link or Admin SDK).
const asVerified = (uid, email) => env.authenticatedContext(uid, { email, email_verified: true }).firestore();

// ---- users / roles -------------------------------------------------------
test('self-registration is denied until the email is verified', async () => {
  const unverified = as('newU', 'newU@x.com');
  await assertFails(setDoc(doc(unverified, 'users/newU'), { email: 'newU@x.com', name: 'N', role: 'customer', phone: null, branch: null, isActive: true, createdAt: serverTimestamp() }));
  const explicitlyFalse = env.authenticatedContext('newF', { email: 'newF@x.com', email_verified: false }).firestore();
  await assertFails(setDoc(doc(explicitlyFalse, 'users/newF'), { email: 'newF@x.com', name: 'N', role: 'customer', phone: null, branch: null, isActive: true, createdAt: serverTimestamp() }));
});
test('customer can self-register only as customer, active, verified, with own email', async () => {
  const db = asVerified('new1', 'new1@x.com');
  const base = { email: 'new1@x.com', name: 'N', role: 'customer', phone: null, branch: null, isActive: true, createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(doc(db, 'users/new1'), base));
});
test('self-registration as owner/staff is denied', async () => {
  const db = asVerified('new2', 'new2@x.com');
  const base = { email: 'new2@x.com', name: 'N', phone: null, branch: null, isActive: true, createdAt: serverTimestamp() };
  await assertFails(setDoc(doc(db, 'users/new2'), { ...base, role: 'owner' }));
  await assertFails(setDoc(doc(db, 'users/new2'), { ...base, role: 'staff' }));
});
test('self-registration with someone else\'s email is denied', async () => {
  const db = asVerified('new3', 'new3@x.com');
  await assertFails(setDoc(doc(db, 'users/new3'), { email: 'ceo@x.com', name: 'N', role: 'customer', phone: null, branch: null, isActive: true, createdAt: serverTimestamp() }));
});
test('user cannot change own role, branch or reactivate self', async () => {
  await assertFails(updateDoc(doc(as('staffA'), 'users/staffA'), { role: 'owner' }));
  await assertFails(updateDoc(doc(as('staffA'), 'users/staffA'), { branch: 'Los Baños Hub' }));
  await assertFails(updateDoc(doc(as('staffOff'), 'users/staffOff'), { isActive: true }));
  await assertSucceeds(updateDoc(doc(as('staffA'), 'users/staffA'), { name: 'New Name' }));
});
test('only owner can create staff profiles / read other users', async () => {
  const staff = { email: 's@x.com', name: 'S', role: 'staff', phone: null, branch: 'Calamba Branch', isActive: true, createdAt: serverTimestamp() };
  await assertSucceeds(setDoc(doc(as('owner1'), 'users/s9'), staff));
  await assertFails(setDoc(doc(as('staffA'), 'users/s10'), staff));
  await assertFails(getDoc(doc(as('cust1'), 'users/cust2')));
  await assertSucceeds(getDoc(doc(as('cust1'), 'users/cust1')));
});
test('deactivated staff lose all privileges immediately', async () => {
  await assertFails(getDoc(doc(as('staffOff'), 'inventory/b1')));
});

// ---- products / inventory ------------------------------------------------
test('products: public read, owner-only write (staff cannot change prices)', async () => {
  await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), 'products/p1')));
  await assertFails(updateDoc(doc(as('staffA'), 'products/p1'), { price: 1 }));
  await assertSucceeds(updateDoc(doc(as('owner1'), 'products/p1'), { price: 120 }));
});
test('inventory: staff limited to own branch, no negatives, no delete', async () => {
  await assertSucceeds(updateDoc(doc(as('staffA'), 'inventory/b1'), { quantity: 5 }));
  await assertFails(updateDoc(doc(as('staffA'), 'inventory/b2'), { quantity: 5 }));
  await assertFails(updateDoc(doc(as('staffA'), 'inventory/b1'), { quantity: -1 }));
  await assertFails(updateDoc(doc(as('staffA'), 'inventory/b1'), { branch: 'Los Baños Hub' }));
  await assertFails(deleteDoc(doc(as('staffA'), 'inventory/b1')));
  await assertFails(getDoc(doc(as('cust1'), 'inventory/b1')));
});

// ---- orders --------------------------------------------------------------
test('orders: customer creates only own pending order; cannot edit or read others', async () => {
  await assertSucceeds(setDoc(doc(as('cust1'), 'orders/o2'), { customerId: 'cust1', branch: 'Calamba Branch', status: 'pending', total: 50 }));
  await assertFails(setDoc(doc(as('cust1'), 'orders/o3'), { customerId: 'cust2', branch: 'Calamba Branch', status: 'pending' }));
  await assertFails(setDoc(doc(as('cust1'), 'orders/o4'), { customerId: 'cust1', branch: 'Calamba Branch', status: 'completed' }));
  await assertFails(updateDoc(doc(as('cust1'), 'orders/o1'), { total: 1 }));
  await assertFails(getDoc(doc(as('cust2'), 'orders/o1')));
  await assertSucceeds(getDoc(doc(as('cust1'), 'orders/o1')));
});
test('orders: staff may change status only; rider only if assigned', async () => {
  await assertSucceeds(updateDoc(doc(as('staffA'), 'orders/o1'), { status: 'preparing' }));
  await assertFails(updateDoc(doc(as('staffA'), 'orders/o1'), { total: 1 }));
  await assertSucceeds(updateDoc(doc(as('rider1'), 'orders/o1'), { status: 'outForDelivery' }));
  await assertFails(updateDoc(doc(as('rider1'), 'orders/o1'), { status: 'cancelled' }));
});

// ---- default deny --------------------------------------------------------
test('unknown collections are denied', async () => {
  await assertFails(getDoc(doc(as('owner1'), 'secrets/x')));
});
