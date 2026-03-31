import 'server-only';

import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

type AdminEnv = {
  projectId: string;
  clientEmail: string;
  privateKey: string;
};

function getAdminEnv(): AdminEnv {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId) {
    throw new Error('Missing FIREBASE_PROJECT_ID environment variable.');
  }

  if (!clientEmail) {
    throw new Error('Missing FIREBASE_CLIENT_EMAIL environment variable.');
  }

  if (!privateKey) {
    throw new Error('Missing FIREBASE_PRIVATE_KEY environment variable.');
  }

  return {
    projectId,
    clientEmail,
    privateKey: privateKey.replace(/\\n/g, '\n'),
  };
}

const adminEnv = getAdminEnv();

const adminApp =
  getApps()[0] ??
  initializeApp({
    credential: cert({
      projectId: adminEnv.projectId,
      clientEmail: adminEnv.clientEmail,
      privateKey: adminEnv.privateKey,
    }),
  });

export const adminAuth = getAuth(adminApp);
export const adminDb = getFirestore(adminApp);
