const fs = require('fs');
const https = require('https');
const os = require('os');
const path = require('path');

const targetEmail = process.argv[2];

if (!targetEmail) {
  console.error('Usage: node scripts/make_admin.js <email>');
  process.exit(1);
}

function getAccessToken() {
  try {
    const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
    const data = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    return data.tokens.access_token;
  } catch (e) {
    console.error('Failed to read firebase token:', e.message);
    process.exit(1);
  }
}

async function request(url, options = {}) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });
    req.on('error', reject);
    if (options.body) {
      req.write(options.body);
    }
    req.end();
  });
}

async function run() {
  const token = getAccessToken();
  const cleanEmail = targetEmail.trim().toLowerCase();
  console.log(`Looking for user with email: ${cleanEmail}`);

  // Query Firestore users
  const listRes = await request(
    'https://firestore.googleapis.com/v1/projects/flutter-mega-assignment/databases/(default)/documents/users',
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }
  );

  const docs = listRes.data.documents || [];
  let foundDoc = null;

  for (const doc of docs) {
    const emailField = doc.fields?.email?.stringValue?.toLowerCase();
    if (emailField === cleanEmail) {
      foundDoc = doc;
      break;
    }
  }

  if (!foundDoc) {
    console.log(`No user document found for ${cleanEmail} in Firestore users collection.`);
    console.log(`Current users in Firestore: ${docs.length}`);
    for (const d of docs) {
      console.log(`- ${d.fields?.email?.stringValue} (${d.name.split('/').pop()})`);
    }
    return;
  }

  const docId = foundDoc.name.split('/').pop();
  console.log(`Found user document ${docId}. Updating role to admin...`);

  // Patch document role
  const patchRes = await request(
    `https://firestore.googleapis.com/v1/projects/flutter-mega-assignment/databases/(default)/documents/users/${docId}?updateMask.fieldPaths=role&updateMask.fieldPaths=updatedAt`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fields: {
          role: { stringValue: 'admin' },
          updatedAt: { stringValue: new Date().toISOString() },
        },
      }),
    }
  );

  if (patchRes.status >= 200 && patchRes.status < 300) {
    console.log(`SUCCESS: User ${cleanEmail} (${docId}) is now an ADMIN! 🚀`);
  } else {
    console.error('Failed to update role:', patchRes.status, patchRes.data);
  }
}

run();
