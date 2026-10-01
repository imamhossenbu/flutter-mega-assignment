const fs = require('fs');
const os = require('os');
const path = require('path');

function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const data = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  return data.tokens.access_token;
}

function convertValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: val.toString() };
    return { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return {
      arrayValue: {
        values: val.map(convertValue),
      },
    };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = convertValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

async function uploadProduct(token, product) {
  const id = product.id;
  const fields = {};
  for (const [key, value] of Object.entries(product)) {
    fields[key] = convertValue(value);
  }

  const url = `https://firestore.googleapis.com/v1/projects/flutter-mega-assignment/databases/(default)/documents/products/${id}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error(`Error uploading ${id}: ${res.status} ${errText}`);
    return false;
  }
  return true;
}

async function run() {
  const token = getAccessToken();
  const products = JSON.parse(fs.readFileSync('scripts/products.json', 'utf8'));
  console.log(`Uploading ${products.length} products to Firestore via fetch...`);

  let successCount = 0;
  // Upload in chunks of 5
  for (let i = 0; i < products.length; i += 5) {
    const chunk = products.slice(i, i + 5);
    const results = await Promise.all(chunk.map((p) => uploadProduct(token, p)));
    successCount += results.filter(Boolean).length;
    process.stdout.write(`Uploaded ${successCount}/${products.length}\r`);
  }

  console.log(`\nSuccessfully synced ${successCount}/${products.length} products to Firestore! 🎉`);
}

run();
