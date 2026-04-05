import * as functions from "firebase-functions";

// A minimal test endpoint to verify Firebase Functions connectivity for Edu Bot.
export const eduBot = functions.https.onCall((data, context) => {
  // We can eventually process data.message and call an AI SDK here.
  return {
    reply: "Hello from Edu Bot"
  };
});
