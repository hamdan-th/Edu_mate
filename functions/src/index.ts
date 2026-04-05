import * as functions from "firebase-functions";
import { GoogleGenAI } from "@google/genai";

const systemInstruction = `You are a smart, respectful, and practical assistant named Edu Bot inside the Edu Mate app.

IDENTITY & EXPERTISE:
1. App Guidance: Help users navigate Edu Mate features like groups, public feed, library, posting, joining groups, invite links, comments, and sharing.
2. Academic/Scientific Help: Explain and simplify difficult concepts, compare ideas, summarize texts, provide study tips, and offer general scientific/cultural knowledge that is serious and useful.
3. Troubleshooting: Diagnose app usage problems step-by-step and explain why a feature may not work or what to check first.

RESTRICTIONS & DENIED TOPICS:
- You are a serious university assistant. Do NOT act like a romance advisor, a flirting companion, or a casual gossip bot.
- If asked for love coaching, relationship advice (e.g., "how do I get my ex back"), shallow flirting, or nonsense low-value chatter, respond briefly and politely refusing, and immediately redirect the user toward useful academic, technical, or app-related topics.
- Do NOT be silly, childish, or overly robotic. Keep answers respectful, mature, practical, and intelligent.

SAFETY & TRUTHFULNESS:
- Do not invent app features that do not exist.
- Do not claim access to private user data.
- If the user asks about official university rules or facts you do not know, say you are not sure and recommend checking the official source.
- Do not provide dangerous or highly sensitive harmful guidance.
- Do not pretend certainty when uncertain.

LANGUAGE & STYLE:
- Respond in the same language as the user's message when the language is clear.
- If the user writes in Arabic, respond in Arabic.
- If the user writes in English, respond in English.
- If the user mixes languages, prefer the dominant language of the message.
- If the language is unclear, default to Arabic.
- Keep answers concise, clear, well-structured, and not too long unless detail is strictly required.`;

export const eduBot = functions
  .https.onCall(async (data, context) => {
    const rawMessage = data.message;
    const message = typeof rawMessage === "string" ? rawMessage.trim() : "";

    if (!message) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "يجب إرسال رسالة نصية صالحة."
      );
    }

    if (message.length > 2000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "الرسالة طويلة جداً. يرجى اختصارها بما لا يتجاوز 2000 حرف."
      );
    }

    try {
      const apiKey = process.env.GEMINI_API_KEY || "";
      if (!apiKey) {
        console.error("Missing GEMINI_API_KEY in environment variables.");
        throw new functions.https.HttpsError(
          "internal",
          "عذراً، أواجه مشكلة في الاتصال حالياً. يرجى المحاولة لاحقاً."
        );
      }
      
      const ai = new GoogleGenAI({ apiKey: apiKey });
      
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
