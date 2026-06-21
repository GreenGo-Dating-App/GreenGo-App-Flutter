/**
 * Instrumentation codemod.
 *
 * Wraps the handler argument of every exported Cloud Function trigger with
 * `monitored('<exportName>', <handler>)` from src/shared/monitoring.ts, and
 * inserts the import where needed. Idempotent — running it again is a no-op.
 *
 * It also emits scripts/monitored-functions.json (the canonical list of
 * instrumented function names + category), which the admin panel registry
 * consumes so the UI toggles always match what the functions record.
 *
 * Usage:  node scripts/instrument-monitoring.cjs        (apply)
 *         node scripts/instrument-monitoring.cjs --dry   (report only)
 */

const fs = require('fs');
const path = require('path');
const ts = require('typescript');

const DRY = process.argv.includes('--dry');
const ROOT = path.resolve(__dirname, '..');
const SRC = path.join(ROOT, 'src');
const MONITORING_MODULE = path.join(SRC, 'shared', 'monitoring.ts');

// Trigger "methods"/factories whose handler is the LAST argument.
const TRIGGERS = new Set([
  // https
  'onCall', 'onRequest',
  // gen1 firestore / rtdb / pubsub / storage / auth chained handlers
  'onRun', 'onCreate', 'onUpdate', 'onDelete', 'onWrite',
  // gen2 firestore
  'onDocumentCreated', 'onDocumentUpdated', 'onDocumentDeleted', 'onDocumentWritten',
  // gen2 rtdb
  'onValueCreated', 'onValueUpdated', 'onValueDeleted', 'onValueWritten',
  // gen2 scheduler / pubsub / storage / tasks / alerts
  'onSchedule', 'onMessagePublished', 'onObjectFinalized', 'onObjectDeleted',
  'onTaskDispatched', 'onCustomEventPublished',
  // identity blocking
  'beforeUserCreated', 'beforeUserSignedIn',
]);

function listTsFiles(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name === '__tests__') continue;
      out.push(...listTsFiles(full));
    } else if (
      entry.name.endsWith('.ts') &&
      !entry.name.endsWith('.d.ts') &&
      !entry.name.endsWith('.test.ts')
    ) {
      out.push(full);
    }
  }
  return out;
}

// Outermost call expression name (the method actually invoked).
function calleeName(callExpr) {
  const e = callExpr.expression;
  if (ts.isPropertyAccessExpression(e)) return e.name.text;
  if (ts.isIdentifier(e)) return e.text;
  return null;
}

function isHandlerArg(arg) {
  return (
    ts.isArrowFunction(arg) ||
    ts.isFunctionExpression(arg) ||
    ts.isIdentifier(arg)
  );
}

function importSpecifier(file) {
  let rel = path
    .relative(path.dirname(file), MONITORING_MODULE.replace(/\.ts$/, ''))
    .replace(/\\/g, '/');
  if (!rel.startsWith('.')) rel = './' + rel;
  return rel;
}

const results = [];
let filesChanged = 0;

for (const file of listTsFiles(SRC)) {
  if (file === MONITORING_MODULE) continue;
  const base = path.basename(file);
  if (base === 'index.ts' || base === 'index-minimal.ts') continue; // re-exports only

  const text = fs.readFileSync(file, 'utf8');
  const sf = ts.createSourceFile(file, text, ts.ScriptTarget.Latest, true);

  const edits = []; // { start, end, replacement }
  const namesInFile = [];

  for (const stmt of sf.statements) {
    if (!ts.isVariableStatement(stmt)) continue;
    const isExported = (stmt.modifiers || []).some(
      (m) => m.kind === ts.SyntaxKind.ExportKeyword
    );
    if (!isExported) continue;

    for (const decl of stmt.declarationList.declarations) {
      if (!decl.initializer || !ts.isIdentifier(decl.name)) continue;
      let init = decl.initializer;
      // unwrap `as` expressions
      while (ts.isAsExpression(init) || ts.isParenthesizedExpression(init)) {
        init = init.expression;
      }
      if (!ts.isCallExpression(init)) continue;

      const name = calleeName(init);
      if (!name || !TRIGGERS.has(name)) continue;
      if (init.arguments.length === 0) continue;

      const last = init.arguments[init.arguments.length - 1];
      if (!isHandlerArg(last)) continue;

      // Idempotency: already wrapped with monitored(...)
      if (
        ts.isCallExpression(last) &&
        ts.isIdentifier(last.expression) &&
        last.expression.text === 'monitored'
      ) {
        continue;
      }

      const exportName = decl.name.text;
      const argText = text.slice(last.getStart(sf), last.getEnd());
      edits.push({
        start: last.getStart(sf),
        end: last.getEnd(),
        replacement: `monitored(${JSON.stringify(exportName)}, ${argText})`,
      });
      namesInFile.push(exportName);
    }
  }

  if (edits.length === 0) continue;

  // Record results (category = first path segment under src/).
  const relFromSrc = path.relative(SRC, file).replace(/\\/g, '/');
  const category = relFromSrc.includes('/') ? relFromSrc.split('/')[0] : 'root';
  for (const n of namesInFile) {
    results.push({ name: n, category, file: relFromSrc });
  }

  if (DRY) {
    filesChanged++;
    continue;
  }

  // Apply edits from end to start so offsets stay valid.
  edits.sort((a, b) => b.start - a.start);
  let updated = text;
  for (const e of edits) {
    updated = updated.slice(0, e.start) + e.replacement + updated.slice(e.end);
  }

  // Insert import after the last import statement, if not already present.
  if (!/from\s+['"][^'"]*shared\/monitoring['"]/.test(updated)) {
    const importLine = `import { monitored } from '${importSpecifier(file)}';\n`;
    const importRegex = /^[ \t]*import[\s\S]*?from\s+['"][^'"]+['"];?[ \t]*\r?\n/gm;
    let lastImportEnd = 0;
    let m;
    while ((m = importRegex.exec(updated)) !== null) {
      lastImportEnd = m.index + m[0].length;
    }
    updated =
      updated.slice(0, lastImportEnd) + importLine + updated.slice(lastImportEnd);
  }

  fs.writeFileSync(file, updated, 'utf8');
  filesChanged++;
}

results.sort((a, b) =>
  a.category === b.category
    ? a.name.localeCompare(b.name)
    : a.category.localeCompare(b.category)
);

const outPath = path.join(__dirname, 'monitored-functions.json');
if (!DRY) {
  fs.writeFileSync(outPath, JSON.stringify(results, null, 2) + '\n', 'utf8');
}

console.log(
  `${DRY ? '[DRY] ' : ''}Instrumented ${results.length} functions across ${filesChanged} files.`
);
const byCat = {};
for (const r of results) byCat[r.category] = (byCat[r.category] || 0) + 1;
for (const c of Object.keys(byCat).sort()) {
  console.log(`  ${c.padEnd(20)} ${byCat[c]}`);
}
if (!DRY) console.log(`Wrote ${path.relative(ROOT, outPath)}`);
