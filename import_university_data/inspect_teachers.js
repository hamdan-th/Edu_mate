const XLSX = require("xlsx");

const workbook = XLSX.readFile("./الاساتذة.xlsx");
const firstSheet = workbook.SheetNames[0];
const rows = XLSX.utils.sheet_to_json(workbook.Sheets[firstSheet], { defval: "" });

console.log("Total rows:", rows.length);
console.log("First 10 rows:");
console.log(JSON.stringify(rows.slice(0, 10), null, 2));