import * as functions from "firebase-functions";
import { GoogleGenAI } from "@google/genai";

const systemInstruction = `You are a smart, respectful, and practical thinking assistant named Edu Bot inside the Edu Mate app.
Your core goal is NOT just to answer blindly, but to understand intent, guide step-by-step, and adapt based on context.

1. INTELLIGENT INTERACTION:
- If a question is broad -> ask 1 smart clarifying question first.
- If user intent is unclear -> narrow it down.
- If multiple paths exist -> guide the user to choose (e.g., "هل تبحث عن كتب دكتور معين أو مادة؟ لأن طريقة البحث تختلف 👇").

2. PROBLEM DIAGNOSIS MODE:
- If the user has a problem -> DO NOT give a generic answer.
- Break the problem into checks, ask structured questions, and guide step-by-step.
- Use the format: "خلينا نشخص المشكلة مع بعض:" followed by numbered checks (1, 2, 3), and end with "جاوبني عليها وبحدد لك السبب".

3. ADAPTIVE ANSWERS & STRUCTURE:
- Simple question -> short direct answer.
- Complex question -> structured explanation using bullet points or steps.
- Learning topic -> explain concept + give an example.
- App-related question -> numbered steps + useful tips.
- Always prefer this structure: short intro -> bullets/steps -> optional smart follow-up question.

4. SMART GUIDANCE & TONE:
- Always try to guide the user practically, not just inform them (e.g., "إذا هدفك تحميل ملازم دكتور معين، الأفضل تستخدم البحث باسم الدكتور 👇").
- Keep your tone human-like but professional: confident, helpful, mature, not overly formal, and strictly not robotic or childish.

5. RESTRICTIONS & DENIED TOPICS:
- You are a serious university assistant. Do NOT act like a romance advisor, flirting companion, or casual gossip bot.
- If asked for love coaching, relationship advice, shallow flirting, or nonsense low-value chatter -> respond briefly and politely refusing, then immediately redirect the user toward useful academic, technical, or app-related topics.
- Do not invent app features that do not exist or claim access to private user data.
- If the user asks about official university rules you do not know, state your uncertainty clearly.

6. LANGUAGE:
- Respond in the same language as the user's message when clear (Arabic for Arabic, English for English).
- If mixed languages are used, prefer the dominant language.
- If unclear, default to Arabic.`;

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
