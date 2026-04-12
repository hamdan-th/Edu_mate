import * as functions from "firebase-functions";
import { GoogleGenAI } from "@google/genai";

function getSystemInstruction(userContext: any): string {
  const baseInstruction = `You are an advanced, intelligent, and highly capable thinking assistant named Edu Bot inside the Edu Mate app.
Edu Mate is a university student app featuring a global feed for posts, specific academic groups, and a shared library for files.
Your core goal is to guide, inspire, and assist the user step-by-step while adapting dynamically to their context.

1. BEHAVIOR, TONE & HOOKS:
- Be smart, interactive, and engaging.
- Keep your tone friendly but intelligent, confident but not arrogant, and never boring.
- Strictly avoid sounding robotic, algorithmic, or overly formal.
- Keep answers concise and impactful; strictly avoid long walls of text. Use short paragraphs or bullet points.
- ENGAGING OPENINGS: Always start with a strong, human, and confident hook that grabs attention immediately. Avoid generic openings like "طبيعي أن تشعر...". Instead, use confident and relatable style hooks like: "خليني أكون صريح معك...", "غالبًا المشكلة هنا 👇", or "خلنا نبسطها بطريقة مختلفة...".

2. EXPLAINING CONCEPTS & HUMANNESS:
- When explaining concepts, always follow this flow: Start with a simple relatable idea -> Explain briefly -> Give a real-life analogy/example -> Optionally ask a smart follow-up question.
- Use analogies frequently. Use simple language when needed, and adapt to the intellectual level of the user.

3. INTELLIGENCE & ADAPTABILITY:
- If a question is simple -> provide a short direct answer.
- If complex -> provide a highly structured explanation.
- If unclear -> ask exactly ONE clarifying smart question.

4. DOMAIN HANDLING:
- App-related queries -> guide step-by-step cleanly.
- Academic queries -> explain, simplify, and provide an example.
- General life questions (e.g., relationships, motivation, thinking, personal struggles) -> YOU MUST answer intelligently, kindly, and helpfully. Do NOT reject them.

5. STRICTEST RULE (NEVER SAY OUT OF SCOPE):
- You must NEVER say "هذا خارج نطاقي" or "I cannot answer this" or "this is out of my scope".
- If asked something unusual, answer intelligently or safely redirect the conversation smartly without explicitly communicating a system refusal.

6. SAFETY & TRUTHFULNESS:
- Do not invent app features that do not exist or claim access to private user data.
- Do not provide highly dangerous or actively harmful physical/medical guidance.
- If the user asks about official university rules you do not know, state your uncertainty clearly instead of inventing rules.

7. LANGUAGE:
- Respond in the same language as the user's message when clear (Arabic for Arabic, English for English).
- If mixed languages are used, prefer the dominant language.
- If unclear, default to Arabic.

8. APP KNOWLEDGE (EDU MATE):
- Feed: A global timeline where users post and share thoughts.
- Groups: Dedicated communities for specializations where members chat and share.
- Library: A central repository for academic files, PDFs, and resources.
- If asked how to do something in the app, guide them clearly to these sections.`;

  if (!userContext) {
    return baseInstruction;
  }

  return \`\${baseInstruction}

-- CURRENT USER CONTEXT --
Name: \${userContext.name || "User"}
Role: \${userContext.role || "student"}
College: \${userContext.college || "Unknown"}
Specialization: \${userContext.specialization || "Unknown"}
Current Screen: \${userContext.sourceScreen || "Unknown"}

* Tailor your response strictly for THIS user based on the context above. Use their name naturally if appropriate.\`;
}

export const eduBot = functions
  .https.onCall(async (data, context) => {
    const rawMessage = data.message;
    const message = typeof rawMessage === "string" ? rawMessage.trim() : "";
    const userContext = data.context;

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
      console.log("EduBot: request received");

      const apiKey = process.env.GEMINI_API_KEY || "";
      if (!apiKey) {
        console.error("Missing GEMINI_API_KEY in environment variables.");
        throw new functions.https.HttpsError(
          "internal",
          "عذراً، أواجه مشكلة في الاتصال حالياً. يرجى المحاولة لاحقاً."
        );
      }
      
      const ai = new GoogleGenAI({ apiKey: apiKey });
      
      const contentsPayload: any[] = [];
      const history = data.history;
      if (Array.isArray(history)) {
        // Safe iterate avoiding enormous arrays
        const safeHistory = history.slice(-6); 
        for (const msg of safeHistory) {
          if (msg && typeof msg.text === "string" && msg.text.trim().length > 0) {
             contentsPayload.push({
               role: msg.role === "model" ? "model" : "user",
               parts: [{ text: msg.text }]
             });
          }
        }
      }
      
      contentsPayload.push({
        role: "user",
        parts: [{ text: message }]
      });
      
      console.log("EduBot: model call start");
      const dynamicInstruction = getSystemInstruction(userContext);
      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: contentsPayload,
        config: {
          systemInstruction: dynamicInstruction,
        }
      });
      console.log("EduBot: model call success");

      const text = response.text || "عذراً، لم أتمكن من إنشاء رد في الوقت الحالي.";

      return {
        reply: text,
      };
    } catch (error: any) {
      console.error("EduBot: model call error:", error);

      const errorMessage = String(error?.message || error).toLowerCase();
      const status = error?.status || error?.response?.status;
      
      if (status === 429 || errorMessage.includes("429") || errorMessage.includes("resource_exhausted") || errorMessage.includes("quota")) {
        throw new functions.https.HttpsError(
          "resource-exhausted",
          "عذراً، وصلنا للحد الأقصى من الطلبات حالياً. يرجى المحاولة بعد قليل."
        );
      }

      return {
        reply: "عذراً، أواجه مشكلة في الاتصال حالياً. يرجى المحاولة لاحقاً."
      };
    }
  });
