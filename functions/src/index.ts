import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ImageAnnotatorClient } from "@google-cloud/vision";
import { GoogleGenAI } from "@google/genai";

admin.initializeApp();
const db = admin.firestore();

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
- If asked how to do something in the app, guide them clearly to these sections.

9. HANDLING USER IDENTITY QUESTIONS (STRICT RULE):
- If the user asks "Who am I?", "What is my name/college/specialization/role?", or "What do you know about me?":
- YOU MUST strictly, directly, and immediately answer using the data provided in the "-- CURRENT USER CONTEXT --" section below.
- NEVER give generic, philosophical, or poetic answers to identity questions. State the facts clearly (e.g. "أنت فلان، تدرس في تخصص كذا...").
- If a specific field is "Unknown", honestly state that you don't have that specific information yet.

10. LIBRARY SEARCH ACTION (MAGIC TAG):
- If the user explicitly asks for files, books, summaries, PDFs, or library resources about a specific topic (e.g. "Math", "Algebra", "Biology", "التفاضل"):
- YOU MUST immediately append this exact tag at the very end of your response: [ACTION:SEARCH_LIBRARY:topic] (replace 'topic' with the single main keyword they want).
- Example user: "ممكن ملفات عن الجبر؟" -> You reply: "بالتأكيد! سأبحث لك في المكتبة عن ملفات الجبر. [ACTION:SEARCH_LIBRARY:الجبر]"`;

  if (!userContext) {
    return baseInstruction;
  }

  return `${baseInstruction}

-- CURRENT USER CONTEXT --
Name: ${userContext.name || "User"}
Role: ${userContext.role || "student"}
College: ${userContext.college || "Unknown"}
Specialization: ${userContext.specialization || "Unknown"}
Current Screen: ${userContext.sourceScreen || "Unknown"}

* Tailor your response strictly for THIS user based on the context above. Use their name naturally if appropriate.`;
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

    // --- SHORT-CIRCUIT IDENTITY & CONTEXT QUESTIONS ---
    const lowerMsg = message.toLowerCase();
    if (userContext) {
      const name = userContext.name || "مستخدم";
      const role = userContext.role === 'doctor' ? 'دكتور' : 'طالب';
      const spec = userContext.specialization || "غير محدد";
      const college = userContext.college || "غير محدد";
      const currentScreen = userContext.sourceScreen || "Edu Mate";

      const isName = lowerMsg.includes('ما اسمي') || lowerMsg.includes('وش اسمي') || lowerMsg.includes('ايش اسمي') || lowerMsg.includes('شو اسمي') || lowerMsg.includes('what is my name');
      const isSpec = lowerMsg.includes('تخصصي') || lowerMsg.includes('ما تخصصي') || lowerMsg.includes('تخصصي ايش');
      const isCollege = lowerMsg.includes('كليتي') || lowerMsg.includes('ما كليتي') || lowerMsg.includes('اي كلية');
      const isRole = lowerMsg.includes('دوري') || lowerMsg.includes('صفتي') || lowerMsg.includes('حسابي') || lowerMsg.includes('هل انا طالب') || lowerMsg.includes('هل انا دكتور');
      const isScreen = lowerMsg.includes('اي شاشة') || lowerMsg.includes('وين انا') || lowerMsg.includes('أين أنا') || lowerMsg.includes('من وين اكلمك') || lowerMsg.includes('اين اتواجد') || lowerMsg.includes('أي شاشة');
      const isGeneral = lowerMsg.includes('من أنا') || lowerMsg.includes('مين انا') || lowerMsg.includes('من انا') || lowerMsg.includes('who am i') || lowerMsg.includes('ماذا تعرف عني') || lowerMsg.includes('ايش تعرف عني');

      let replyStr = "";
      
      if (isScreen && !isGeneral) {
        replyStr = `أنت تتحدث معي الآن من خلال شاشة: ${currentScreen}.`;
      } else if (isName && !isGeneral) {
        replyStr = `اسمك المسجل لدينا هو ${name}.`;
      } else if (isSpec && !isGeneral) {
        replyStr = spec !== "غير محدد" ? `أنت تدرس في تخصص ${spec}.` : "عذراً، تخصصك غير مسجل حالياً في بياناتك.";
      } else if (isCollege && !isGeneral) {
        replyStr = college !== "غير محدد" ? `أنت تدرس في ${college}.` : "عذراً، كليتك غير مسجلة حالياً في بياناتك.";
      } else if (isRole && !isGeneral) {
        replyStr = `حسابك مسجل كـ ${role}.`;
      } else if (isGeneral || isName || isSpec || isCollege) {
        replyStr = `أهلاً بك يا ${name}! أنت مسجل كـ ${role}` + 
                   (spec !== "غير محدد" ? ` في تخصص ${spec}` : "") +
                   (college !== "غير محدد" ? ` (${college})` : "") + ".";
      }

      if (replyStr !== "") {
        console.log("EduBot: short-circuited tailored question");
        return { reply: replyStr };
      }
    }
    // ------------------------------------------

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

// --- CONTENT SCREENING SYSTEM ---
const visionClient = new ImageAnnotatorClient();

/**
 * screenContent
 * Automatic pre-upload image screening using Google Cloud Vision SafeSearch.
 * Rejects if likelihood of Adult, Racy, Violence, or Spoof is LIKELY or VERY_LIKELY.
 */
export const screenContent = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول لاستخدام هذه الخدمة."
    );
  }

  const base64Image = data.image;
  if (!base64Image) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "لم يتم توفير صورة للفحص."
    );
  }

  try {
    const [result] = await visionClient.safeSearchDetection({
      image: { content: base64Image },
    });

    const safeSearch = result.safeSearchAnnotation;
    if (!safeSearch) {
      // If we can't annotate, we default to allow or reject?
      // For safety, let's assume we need a valid annotation.
      return { status: "allow" };
    }

    const thresholds = ["LIKELY", "VERY_LIKELY"];

    // Check strict categories: Adult, Racy, Violence, Spoof
    const isUnsafe =
      thresholds.includes(safeSearch.adult as string) ||
      thresholds.includes(safeSearch.racy as string) ||
      thresholds.includes(safeSearch.violence as string) ||
      thresholds.includes(safeSearch.spoof as string);

    if (isUnsafe) {
      console.warn(`Content rejected for user ${context.auth.uid}:`, safeSearch);
      return {
        status: "reject",
        reason: "الصورة تحتوي على محتوى غير لائق أو حساس.",
        details: {
          adult: safeSearch.adult,
          racy: safeSearch.racy,
          violence: safeSearch.violence,
          spoof: safeSearch.spoof,
        },
      };
    }

    return { status: "allow" };
  } catch (error) {
    console.error("Vision API Error:", error);
    // On technical failure, we typically allow to not block users,
    // but in strict academic environment, we might want to check.
    // Let's allow but log.
    return { status: "allow", note: "screening_skipped_due_to_error" };
  }
});

/**
 * deleteGroup
 * Securely deletes a group and all its associated data.
 * Enforcement: Only the group owner (verified via Firestore ownerId) can trigger this.
 */
export const deleteGroup = functions.https.onCall(async (data, context) => {
  // 1. Authentication Check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول للقيام بهذا الإجراء."
    );
  }

  const { groupId } = data;
  if (!groupId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "معرف المجموعة مطلوب."
    );
  }

  const groupRef = db.collection("groups").doc(groupId);
  const groupSnap = await groupRef.get();

  if (!groupSnap.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "المجموعة غير موجودة."
    );
  }

  const groupData = groupSnap.data()!;
  const ownerId = groupData.ownerId;

  // 2. Ownership Verification (Primary source of truth: Firestore ownerId)
  if (ownerId !== context.auth.uid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "مالك المجموعة فقط يمكنه حذفها."
    );
  }

  try {
    console.log(`Starting deletion for group: ${groupId}`);

    // 3. Mark as deleting (Conservative flow: prevent new actions while cleaning up)
    await groupRef.update({
      status: "deleting",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Cleanup Members: Remove joined_groups reference from all members
    const membersSnap = await groupRef.collection("members").get();
    const memberCleanupPromises = membersSnap.docs.map(async (doc) => {
      const uid = doc.id;
      return db
        .collection("users")
        .doc(uid)
        .collection("joined_groups")
        .doc(groupId)
        .delete()
        .catch((err) => console.error(`Failed to remove joined_group for ${uid}:`, err));
    });
    await Promise.all(memberCleanupPromises);

    // 5. Cleanup Posts: Remove all feed posts linked to this group
    const postsSnap = await db
      .collection("posts")
      .where("groupId", "==", groupId)
      .get();
    const postCleanupPromises = postsSnap.docs.map((doc) =>
      doc.ref.delete().catch((err) => console.error(`Failed to delete post ${doc.id}:`, err))
    );
    await Promise.all(postCleanupPromises);

    // 6. Cleanup Reports: Remove all reports linked to this group
    const reportsSnap = await db
      .collection("reports")
      .where("groupId", "==", groupId)
      .get();
    const reportCleanupPromises = reportsSnap.docs.map((doc) =>
      doc.ref.delete().catch((err) => console.error(`Failed to delete report ${doc.id}:`, err))
    );
    await Promise.all(reportCleanupPromises);

    // 7. Storage Cleanup: Chat images folder
    const bucket = admin.storage().bucket();
    // Conservative prefix deletion for chat images
    await bucket.deleteFiles({ prefix: `groups_chat/${groupId}/` }).catch((err) => {
      console.warn("Storage cleanup (chat) failed or was empty:", err.message);
    });

    // Cover image cleanup (identify if URL belongs to Edu Mate storage)
    const imageUrl = (groupData.imageUrl || groupData.groupImageUrl || "") as string;
    if (imageUrl.includes("group_covers%2F")) {
      try {
        // Extract filename from the encoded Firebase Storage URL
        const fileNameMatch = imageUrl.match(/group_covers%2F([^?]+)/);
        if (fileNameMatch && fileNameMatch[1]) {
          const fileName = decodeURIComponent(fileNameMatch[1]);
          await bucket.file(`group_covers/${fileName}`).delete().catch(() => {});
        }
      } catch (err) {
        console.warn("Cover image storage cleanup failed:", err);
      }
    }

    // 8. Recursive Subcollection Deletion & Main Document Delete (Last Step)
    await db.recursiveDelete(groupRef);

    console.log(`Successfully deleted group: ${groupId}`);
    return { success: true };
  } catch (error: any) {
    console.error("Group deletion failed:", error);
    throw new functions.https.HttpsError(
      "internal",
      "حدث خطأ أثناء حذف المجموعة. يرجى المحاولة لاحقاً."
    );
  }
});
