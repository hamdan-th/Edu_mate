const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const XLSX = require("xlsx");
const iconv = require("iconv-lite");
const { parse } = require("csv-parse/sync");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const REGISTRY_COLLECTION = "university_registry";

function clean(value) {
  if (value === undefined || value === null) return "";
  return String(value).trim();
}

function normalizeStudentRow(row) {
  const identifier =
    clean(row["الرقم_الأكاديمي"]) ||
    clean(row["StudId"]) ||
    clean(row["studid"]);

  if (!identifier) return null;

  return {
    identifier,
    identifierType: "academic",
    role: "student",
    fullName:
      clean(row["اسم_الطالب_ع"]) ||
      clean(row["اسم الطالب"]) ||
      clean(row["name"]),
    collegeName:
      clean(row["اسم_الكلية_ع"]) ||
      clean(row["الكلية"]),
    departmentName:
      clean(row["اسم_القسم_ع"]) ||
      clean(row["القسم"]),
    specializationName:
      clean(row["التخصص_ع"]) ||
      clean(row["التخصص"]),
    email: clean(row["email"]),
    isDoctorVerified: false,
    isStudentVerified: false,
    verificationType: null,
    source: "students_csv",
    isActive: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function normalizeDoctorRows(rows) {
  const results = [];

  for (let i = 0; i < rows.length - 1; i++) {
    const current = rows[i];
    const next = rows[i + 1];

    const currentA = clean(current["Republic of Yemen"]);
    const currentB = clean(current["الجمهورية اليمنية"]);

    const nextA = clean(next["Republic of Yemen"]);
    const nextB = clean(next["الجمهورية اليمنية"]);
    const specialization = clean(next["تقـــرير مؤهلات الموظفين"]);
    const qualificationType = clean(next[" 2026/03/31"]);

    const isNameRow =
      currentA &&
      isNaN(Number(currentA)) &&
      currentA !== "تاريخ التخرج";

    const looksLikeDataRow =
      (nextA || nextB || specialization || qualificationType) &&
      (!isNaN(Number(nextA)) || !isNaN(Number(nextB)));

    if (!isNameRow || !looksLikeDataRow) continue;

    const identifier = nextB || nextA;
    const fullName = currentA;

    if (!identifier || !fullName) continue;

    results.push({
      identifier: String(identifier),
      identifierType: "employee",
      role: "doctor",
      fullName,
      collegeName: "",
      departmentName: "",
      specializationName: specialization,
      qualificationType,
      email: "",
      isDoctorVerified: true,
      isStudentVerified: false,
      verificationType: "doctor",
      source: "staff_xlsx",
      isActive: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    i++; // تخطي صف البيانات لأنه تم استهلاكه مع صف الاسم
  }

  return results;
}

function readCsvFile(filePath) {
  const raw = fs.readFileSync(filePath);
  const decoded = iconv.decode(raw, "utf16-le");
  return parse(decoded, {
    columns: true,
    skip_empty_lines: true,
    relax_column_count: true,
    delimiter: "\t",
  });
}

function readXlsxFile(filePath) {
  const workbook = XLSX.readFile(filePath);
  const firstSheet = workbook.SheetNames[0];
  return XLSX.utils.sheet_to_json(workbook.Sheets[firstSheet], { defval: "" });
}

async function upsertRegistry(record) {
  const ref = db.collection(REGISTRY_COLLECTION).doc(record.identifier);
  await ref.set(
    {
      ...record,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

async function importStudents(filePath) {
  console.log(`Reading students: ${filePath}`);
  const rows = readCsvFile(filePath);

  let count = 0;
  for (const row of rows) {
    const normalized = normalizeStudentRow(row);
    if (!normalized) continue;
    await upsertRegistry(normalized);
    count++;
  }

  console.log(`Imported students from ${path.basename(filePath)}: ${count}`);
}

async function importDoctors(filePath) {
  console.log(`Reading doctors: ${filePath}`);
  const rows = readXlsxFile(filePath);
  const normalizedRows = normalizeDoctorRows(rows);

  let count = 0;
  for (const normalized of normalizedRows) {
    await upsertRegistry(normalized);
    count++;
  }

  console.log(`Imported doctors from ${path.basename(filePath)}: ${count}`);
}

async function main() {
  try {
    await importStudents("./اسماء الاي تي.csv");
    await importStudents("./اسماء الامن السيبراني (1) (1).csv");
    await importDoctors("./الاساتذة.xlsx");

    console.log("Import completed successfully.");
    process.exit(0);
  } catch (error) {
    console.error("Import failed:", error);
    process.exit(1);
  }
}

main();