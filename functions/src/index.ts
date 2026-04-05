import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenAI } from "@google/genai";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const systemInstruction = `You are Edu Bot inside the Edu Mate app.
You help university students with:
- using the app
- groups
- library
- public feed
- study help
- academic guidance in a general way

Rules:
- answer clearly and practically
- prefer Arabic
- keep answers concise but useful
- if the user asks about official university rules or facts you do not know, say you are not sure and recommend checking the official source
- do not claim access to private student data
- do not invent app features that do not exist
- do not provide dangerous or highly sensitive guidance beyond a safe general level`;

export const eduBot = functions
  .runWith({ secrets: [geminiApiKey] })
  .https.onCall(async (data, context) => {
    try {
      const message = data.message;
      if (!message || typeof message !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "The function must be called with a valid 'message' string."
        );
      }

      const ai = new GoogleGenAI({ apiKey: geminiApiKey.value() });
      
      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: message,
        config: {
          systemInstruction: systemInstruction,
        }
      });

      const text = response.text || "عذراً، لم أتمكن من إنشاء رد في الوقت الحالي.";

      return {
        reply: text,
      };
    } catch (error) {
      console.error("EduBot Generation Error:", error);
      return {
        reply: "عذراً، أواجه مشكلة في الاتصال حالياً. يرجى المحاولة لاحقاً."
      };
    }
  });
