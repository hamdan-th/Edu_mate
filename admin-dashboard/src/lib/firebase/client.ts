import 'client-only';

import { getApps, initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

type ClientEnv = {
  apiKey: string;
  authDomain: string;
  projectId: string;
  storageBucket: string;
  messagingSenderId: string;
  appId: string;
};

function getClientEnv(): ClientEnv {
  const apiKey = process.env.NEXT_PUBLIC_FIREBASE_API_KEY;
  const authDomain = process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN;
  const projectId = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID;
  const storageBucket = process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET;
  const messagingSenderId = process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID;
  const appId = process.env.NEXT_PUBLIC_FIREBASE_APP_ID;

  if (!apiKey) {
    throw new Error('Missing NEXT_PUBLIC_FIREBASE_API_KEY environment variable.');
  }
  if (!authDomain) {
    throw new Error('Missing NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN environment variable.');
  }
  if (!projectId) {
    throw new Error('Missing NEXT_PUBLIC_FIREBASE_PROJECT_ID environment variable.');
  }
  if (!storageBucket) {
    throw new Error('Missing NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET environment variable.');
  }
  if (!messagingSenderId) {
    throw new Error('Missing NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID environment variable.');
  }
  if (!appId) {
    throw new Error('Missing NEXT_PUBLIC_FIREBASE_APP_ID environment variable.');
  }

  return {
    apiKey,
    authDomain,
    projectId,
    storageBucket,
    messagingSenderId,
    appId,
  };
}

const firebaseConfig = getClientEnv();

const app = getApps().length ? getApps()[0] : initializeApp(firebaseConfig);

export const firebaseAuth = getAuth(app);
export const firebaseDb = getFirestore(app);
export const firebaseStorage = getStorage(app);
