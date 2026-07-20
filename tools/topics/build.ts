// お題CSV → アプリ同梱JSON の変換＋検証スクリプト
// 実行: node --experimental-strip-types tools/topics/build.ts
// 入力: tools/topics/topics.csv（LLM下書き→人手チェック済みの台帳）
// 出力: App/Resources/topics.json

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

type Difficulty = "easy" | "normal" | "hard";

interface Topic {
  id: string;
  text: string;
  furigana: string;
  difficulty: Difficulty;
  category: string;
  free: boolean;
}

const root = join(dirname(fileURLToPath(import.meta.url)), "../..");
const csvPath = join(root, "tools/topics/topics.csv");
const outPath = join(root, "App/Resources/topics.json");

const HIRAGANA = /^[ぁ-ゖー]+$/;
const DIFFICULTIES: Difficulty[] = ["easy", "normal", "hard"];
const FREE_PER_DIFFICULTY = 10;

function fail(message: string): never {
  console.error(`NG: ${message}`);
  process.exit(1);
}

const lines = readFileSync(csvPath, "utf8").trim().split("\n");
const header = lines.shift();
if (header !== "id,text,furigana,difficulty,category,free") {
  fail(`CSVヘッダが想定と異なります: ${header}`);
}

const topics: Topic[] = lines.map((line, i) => {
  const cols = line.split(",");
  if (cols.length !== 6) fail(`${i + 2}行目: 列数が6ではありません`);
  const [id, text, furigana, difficulty, category, free] = cols;
  return {
    id,
    text,
    furigana,
    difficulty: difficulty as Difficulty,
    category,
    free: free === "1",
  };
});

// 検証
const seen = new Set<string>();
for (const t of topics) {
  if (!t.id || seen.has(t.id)) fail(`ID重複または空: ${t.id}`);
  seen.add(t.id);
  if (!t.text) fail(`${t.id}: text が空`);
  if (!HIRAGANA.test(t.furigana)) fail(`${t.id}: furigana はひらがなのみ（${t.furigana}）`);
  if (!DIFFICULTIES.includes(t.difficulty)) fail(`${t.id}: difficulty 不正（${t.difficulty}）`);
  if (!t.category) fail(`${t.id}: category が空`);
}
const texts = new Set(topics.map((t) => t.text));
if (texts.size !== topics.length) fail("text（お題本文）に重複があります");

for (const d of DIFFICULTIES) {
  const all = topics.filter((t) => t.difficulty === d);
  const free = all.filter((t) => t.free);
  if (all.length < 30) fail(`${d}: ${all.length}問（30問以上必要）`);
  if (free.length !== FREE_PER_DIFFICULTY) {
    fail(`${d}: 無料枠が${free.length}問（${FREE_PER_DIFFICULTY}問ちょうど必要）`);
  }
  console.log(`OK: ${d} ${all.length}問（無料 ${free.length}問）`);
}

writeFileSync(
  outPath,
  JSON.stringify({ schemaVersion: 1, topics }, null, 2) + "\n"
);
console.log(`OK: 合計 ${topics.length}問 → ${outPath}`);
