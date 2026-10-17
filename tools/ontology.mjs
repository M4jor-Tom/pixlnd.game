// Structurizr is the parser. This helper only inspects its official JSON and stages native docs.
import * as fs from 'node:fs';
import path from 'node:path';
import {spawn, spawnSync} from 'node:child_process';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const chapters = ['index', '0_Conventions', '1_Scope', '2_Competency_Questions', '3_Classes', 'controls', 'controller-profiles', '4_Relations', '5_Constraints', '6_Generators', '7_Open_points_for_validation'];
const kinds = new Set(['Class', 'SectionNote', 'RelationDefinition', 'Constraint', 'Generator', 'Question']);
const ordered = (p, pattern) => Object.keys(p).filter(k => pattern.test(k)).sort();
function checkCell(p, k) {
  const state = p[k + '.state'];
  if (!['text', 'empty-cell', 'missing-cell', 'absent-column'].includes(state)) throw Error('Invalid cell: ' + k);
  if ((state === 'text') !== Object.hasOwn(p, k + '.text')) throw Error('Incomplete cell: ' + k);
}
export function documentsFromWorkspace(workspace) {
  const documents = chapters.map(file => ({file: file + '.dsl', records: []}));
  const elements = workspace.model.customElements, byId = new Map(elements.map(e => [e.id, e]));
  const seen = new Set(), verifiedEdges = new Set();
  for (const e of elements) {
    const p = Object.fromEntries(Object.entries(e.properties || {}).filter(([k]) => !k.startsWith('structurizr.')));
    const tags = e.tags.split(',').sort().join(',');
    const expectedTags = e.metadata === 'EndpointTerm' ? ['Element', 'EndpointTerm'] : ['Element', p.kind, p.section || 'Catalog'];
    if (tags !== [...new Set(expectedTags)].sort().join(',') || e.name !== p.id) throw Error('Altered record identity/tags: ' + e.name);
    if (e.metadata === 'EndpointTerm') {
      if (p['definition-status'] !== 'source term without class definition' || Object.keys(p).length !== 2) throw Error('Invalid endpoint term');
      continue;
    }
    if (!kinds.has(p.kind) || p.kind !== e.metadata || !p.id || seen.has(p.id)) throw Error('Unknown/duplicate record: ' + e.name);
    seen.add(p.id);
    for (const k of Object.keys(p)) {
      if (k.endsWith('.state')) checkCell(p, k.slice(0, -6));
      if (k.endsWith('.text') && !/\.column\.\d+\.text$/.test(k)) checkCell(p, k.slice(0, -5));
    }
    const doc = documents.find(d => d.file === p['source.file']?.replace('.md', '.dsl'));
    if (!doc || !Number.isInteger(+p.order)) throw Error('Missing source/order: ' + p.id);
    const edges = e.relationships || [];
    if (p.kind === 'RelationDefinition') for (const side of ['domain', 'range']) {
      for (const k of ordered(p, new RegExp('^' + side + '\\.member\\.\\d+\\.symbol$'))) {
        const prefix = k.slice(0, -7), symbol = p[k], order = prefix.split('.')[2];
        const owner = side === 'domain' ? elements.find(e => e.properties?.id === symbol) : e;
        const edge = owner?.relationships?.find(edge => edge.description === side + ' member' && byId.get(edge.destinationId)?.properties?.id === (side === 'domain' ? p.id : symbol) && edge.properties?.['member-order'] === order);
        if (!edge || edge.properties['qualifier.state'] !== p[prefix + '.qualifier.state'] || edge.properties['qualifier.text'] !== p[prefix + '.qualifier.text']) throw Error('Missing/altered incidence: ' + p.id + ':' + k);
        verifiedEdges.add(edge.id);
      }
    }
    for (const k of ordered(p, /^answer-reference\.\d+\.kind$/)) if (p[k] === 'declared-record') {
      const edge = edges.find(edge => edge.description === 'answered by' && byId.get(edge.destinationId)?.properties?.id === p[k.replace('.kind', '.target')] && edge.properties?.['reference-order'] === k.split('.')[1]);
      if (!edge) throw Error('Missing answer edge: ' + p.id);
      verifiedEdges.add(edge.id);
    }
    doc.records.push({kind: p.kind, locator: p.id, fields: p});
  }
  for (const edge of elements.flatMap(e => e.relationships || [])) if (!verifiedEdges.has(edge.id) || edge.sourceId === edge.destinationId) throw Error('Undeclared/implied relationship: ' + edge.id);
  for (const d of documents) d.records.sort((a, b) => +a.fields.order - +b.fields.order);
  return documents;
}
function value(p, k) { checkCell(p, k); return p[k + '.state'] === 'text' ? p[k + '.text'] : ''; }
function table(columns, rows) { return ['| ' + columns.join(' | ') + ' |', '|' + columns.map(() => '---').join('|') + '|', ...rows.map(row => '| ' + row.join(' | ') + ' |')].join('\n'); }
export function renderDocuments(documents, native = false) {
  const all = new Map(documents.flatMap(d => d.records).map(r => [r.locator, r]));
  const result = new Map();
  for (const d of documents) {
    // Native docs consume H1 as a workspace title; keep other H1 chapters in the navigation.
    const depth = native && d.file !== 'index.dsl' && d.records[0]?.fields['heading.level'] === '1' ? 1 : 0;
    const blocks = ['> GENERATED from authoritative Structurizr DSL. Read-only, non-authoritative; edit DSL, never this output.'];
    for (const r of d.records.filter(r => r.fields.title)) {
      const p = r.fields;
      blocks.push('#'.repeat(+p['heading.level'] + depth) + ' ' + p.title);
      for (const kindKey of ordered(p, /^note\.\d+\.kind$/)) {
        const n = kindKey.slice(0, -4), kind = p[kindKey];
        if (['table', 'catalog-table', 'property-table'].includes(kind)) {
          const prefix = kind === 'property-table' ? 'property.' : n;
          const columns = ordered(p, new RegExp('^' + prefix.replaceAll('.', '\\.') + 'column\\.\\d+\\.text$')).map(k => p[k]);
          let rows;
          if (kind === 'catalog-table') rows = ordered(p, new RegExp('^' + n.replaceAll('.', '\\.') + 'row\\.\\d+\\.target$')).map(k => {
            const row = all.get(p[k]); if (!row) throw Error('Unknown table row ' + p[k]);
            const names = {Question: ['label', 'question', 'answered-by'], RelationDefinition: ['id', 'domain', 'range', 'cardinality', 'meaning'], Constraint: ['id', 'rule', 'layer'], Generator: ['display', 'input', 'output', 'invariants']}[row.kind];
            return names.map(name => name === 'id' ? row.locator : value(row.fields, name));
          });
          else if (kind === 'property-table') rows = ordered(p, /^property\.\d+\.name$/).map(k => {
            const pr = k.slice(0, -4); let row = [p[k]];
            for (const c of columns.slice(1)) {
              const name = c === 'i/e' ? 'i-e' : c;
              if (p[pr + name + '.state'] === 'missing-cell') { if (native) row.push('_missing source cell_'); }
              else row.push(value(p, pr + name));
            }
            return row;
          });
          else rows = ordered(p, new RegExp('^' + n.replaceAll('.', '\\.') + 'row\\.\\d+\\.source\\.start$')).map(k => {
            const prefix = k.slice(0, -12); return columns.map((c, i) => value(p, prefix + 'cell.' + String(i + 1).padStart(3, '0')));
          });
          blocks.push(table(columns, rows));
        } else {
          if (!['paragraph', 'list', 'code', 'footnote'].includes(kind)) throw Error('Unknown note kind ' + kind);
          blocks.push(ordered(p, new RegExp('^' + n.replaceAll('.', '\\.') + 'line\\.\\d+\\.state$')).map(k => value(p, k.slice(0, -6))).join('\n'));
        }
      }
    }
    result.set(d.file.replace('.dsl', '.md'), blocks.join('\n\n') + '\n');
  }
  return result;
}
export function locate(locator, sourceRoot = 'ontology') {
  const found = [];
  for (const file of chapters) {
    const filename = path.join(sourceRoot, 'domain', file + '.dsl'), lines = fs.readFileSync(filename, 'utf8').split('\n');
    let start = 0, id, heading, anchors = [], preHeadingAnchors = [];
    const check = () => { if (id && (id === locator || `${file}.md#${heading}` === locator || `${file}.dsl#${heading}` === locator || anchors.some(a => `${file}.md#${a}` === locator || `${file}.dsl#${a}` === locator))) found.push({file: filename, line: start + 1, locator: id}); };
    lines.forEach((line, i) => {
      if (/^\w+ = element /.test(line)) { check(); start = i; id = undefined; heading = undefined; anchors = preHeadingAnchors; preHeadingAnchors = []; }
      const m = /^\s*"(id|heading.slug)" "(.*)"$/.exec(line);
      const anchor = /^\s*"note\.\d+\.(row\.\d+\.)?anchor\.\d+" "([^"\\]+)"$/.exec(line);
      // Standalone source aliases precede their heading; table-row anchors belong to their table.
      if (anchor) (anchor[1] ? anchors : preHeadingAnchors).push(anchor[2]);
      if (m) { if (m[1] === 'id') id = m[2]; else heading = m[2]; }
    }); check();
  }
  if (found.length !== 1) throw Error('Unknown/ambiguous locator: ' + locator);
  return found[0];
}
function official(sourceRoot, out) {
  if (!process.env.STRUCTURIZR_WAR || !fs.existsSync(process.env.STRUCTURIZR_WAR)) throw Error('Set STRUCTURIZR_WAR to the external Structurizr 2026.09.19 WAR; java 21 must be on PATH');
  // Narrow authored-property check: official DSL permits overwrites, which hide accidental data loss.
  for (const file of [path.join(sourceRoot, 'workspace.dsl'), ...fs.readdirSync(path.join(sourceRoot, 'domain')).filter(f => f.endsWith('.dsl')).map(f => path.join(sourceRoot, 'domain', f))]) {
    let keys;
    for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
      if (line.trim() === 'properties {') keys = new Set();
      else if (line.trim() === '}') keys = undefined;
      else if (keys) {
        const match = /^\s*"([^"\\]+)" /.exec(line);
        if (match) { if (keys.has(match[1])) throw Error('Duplicate authored property: ' + file + ':' + match[1]); keys.add(match[1]); }
      }
    }
  }
  fs.mkdirSync(out, {recursive: true});
  for (const args of [['validate'], ['export', '-format', 'json', '-output', out]]) {
    const run = spawnSync('java', ['-jar', process.env.STRUCTURIZR_WAR, ...args, '-workspace', path.join(sourceRoot, 'workspace.dsl')], {encoding: 'utf8'});
    if (run.error) throw run.error;
    if (run.status !== 0) throw Error(run.stdout + run.stderr);
  }
  return JSON.parse(fs.readFileSync(path.join(out, 'workspace.json'), 'utf8'));
}
const stageMarker = '.ontology-stage.json';
const repositoryRoot = fs.realpathSync(fileURLToPath(new URL('..', import.meta.url)));
const contains = (parent, child) => child === parent || child.startsWith(parent + (parent.endsWith(path.sep) ? '' : path.sep));
function stageContents(dir, prefix = '', runtime = false) {
  const contents = {};
  for (const name of fs.readdirSync(dir).sort()) {
    const relative = prefix + name, filename = path.join(dir, name), stat = fs.lstatSync(filename);
    if (stat.isSymbolicLink() || (!stat.isDirectory() && (!stat.isFile() || stat.nlink !== 1))) throw Error('symlink, hardlink or special file: ' + relative);
    if (runtime) {
      if (stat.isDirectory()) stageContents(filename, relative + '/', true);
      continue; // Validate runtime-owned trees, but never hash, replace or delete them.
    }
    if (!prefix && name === '.structurizr') {
      if (!stat.isDirectory()) throw Error('expected runtime directory: ' + relative);
      stageContents(filename, relative + '/', true); continue;
    }
    if (!prefix && [stageMarker, 'workspace.json'].includes(name)) {
      if (!stat.isFile()) throw Error('expected regular file: ' + relative);
      continue; // Local produces workspace.json; staging never overwrites it.
    }
    if (!prefix && !['domain', 'docs', 'workspace.dsl'].includes(name)) throw Error('unowned content: ' + relative);
    contents[relative] = stat.isDirectory() ? null : createHash('sha256').update(fs.readFileSync(filename)).digest('hex');
    if (stat.isDirectory()) Object.assign(contents, stageContents(filename, relative + '/'));
  }
  return contents;
}
function checkStageDestination(sourceRoot, out) {
  try {
    // Reject aliases, including symlinked parents and dangling links, before creating anything.
    for (let part = out;; part = path.dirname(part)) {
      try { if (fs.lstatSync(part).isSymbolicLink()) throw Error('symlink alias: ' + part); }
      catch (error) { if (error.code !== 'ENOENT') throw error; }
      if (part === path.dirname(part)) break;
    }
    if (contains(out, repositoryRoot) || contains(out, sourceRoot) || contains(sourceRoot, out)) throw Error('repository/source overlap');
    if (!fs.existsSync(out)) return;
    if (!fs.statSync(out).isDirectory()) throw Error('not a directory');
    if (!fs.readdirSync(out).length) return;
    const contents = stageContents(out);
    const owner = JSON.parse(fs.readFileSync(path.join(out, stageMarker), 'utf8'));
    if (owner.version !== 1 || owner.sourceRoot !== sourceRoot || JSON.stringify(owner.contents) !== JSON.stringify(contents)) throw Error('missing ownership or changed generated contents');
  } catch (error) { throw Error('Unsafe viewer destination: ' + out + ': ' + error.message); }
}
export function stage(sourceRoot, out) {
  sourceRoot = fs.realpathSync(sourceRoot); out = path.resolve(out);
  checkStageDestination(sourceRoot, out);
  fs.mkdirSync(path.dirname(out), {recursive: true});
  const temp = fs.mkdtempSync(path.join(path.dirname(out), path.basename(out) + '-build-'));
  try {
    const source = path.join(temp, 'input'); fs.mkdirSync(source);
    fs.copyFileSync(path.join(sourceRoot, 'workspace.dsl'), path.join(source, 'workspace.dsl'));
    fs.cpSync(path.join(sourceRoot, 'domain'), path.join(source, 'domain'), {recursive: true, filter: file => fs.statSync(file).isDirectory() || file.endsWith('.dsl')});
    const workspace = official(source, path.join(temp, 'export'));
    const documents = documentsFromWorkspace(workspace), docs = path.join(source, 'docs'); fs.mkdirSync(docs);
    let i = 0; for (const [file, content] of renderDocuments(documents, true)) {
      // Native local cannot serve repository source files: display honest locators, not fake links.
      const native = content.replace(/\[([^\]]+)\]\(((?!https?:)[^)]+)\)/g, (full, caption, target) => {
        if (!target.endsWith('.dsl')) return `${caption} — \`${target}\` (repository source locator)`;
        const fragment = /\(locator=([^)]*)\)/.exec(caption);
        const file = path.basename(target);
        const record = documents.find(d => d.file === file)?.records[0];
        const found = locate(fragment ? file.replace('.dsl', '.md') + '#' + fragment[1] : record.locator, sourceRoot);
        return `${caption} — \`${found.file}:${found.line}; id=${found.locator}\``;
      });
      fs.writeFileSync(path.join(docs, `${String(i++).padStart(2, '0')}-${file}`), native, {mode: 0o444});
    }
    const wrapper = fs.readFileSync(path.join(source, 'workspace.dsl'), 'utf8').replace(/\n}/, '\n    !docs docs\n}');
    fs.writeFileSync(path.join(source, 'workspace.dsl'), wrapper);
    official(source, path.join(temp, 'documented-export'));
    checkStageDestination(sourceRoot, out); // Parsing may take seconds; refuse intervening destination edits.
    fs.mkdirSync(out, {recursive: true});
    fs.rmSync(path.join(out, 'domain'), {recursive: true, force: true});
    fs.cpSync(path.join(source, 'domain'), path.join(out, 'domain'), {recursive: true});
    // Remove previous generated read-only docs before replacement, never canonical input.
    fs.rmSync(path.join(out, 'docs'), {recursive: true, force: true}); fs.cpSync(docs, path.join(out, 'docs'), {recursive: true});
    fs.writeFileSync(path.join(out, 'workspace.dsl'), wrapper);
    fs.writeFileSync(path.join(out, stageMarker), JSON.stringify({version: 1, sourceRoot, contents: stageContents(out)}));
    console.log('Published validated native docs:', out, 'export bytes:', Buffer.byteLength(JSON.stringify(workspace)));
  } finally { fs.rmSync(temp, {recursive: true, force: true}); }
}
async function main() {
  const args = process.argv.slice(2), arg = (name, fallback) => args.includes(name) ? args[args.indexOf(name) + 1] : fallback;
  const sourceRoot = path.resolve(arg('--source-root', 'ontology')), out = path.resolve(arg('--out', '.structurizr'));
  if (args[0] === 'locate') { const r = locate(args[1], sourceRoot); console.log(`${r.file}:${r.line}; id=${r.locator}`); }
  else if (args[0] === 'export') { official(sourceRoot, out); console.log('Validated/exported:', path.join(out, 'workspace.json')); }
  else if (args[0] === 'view') {
    stage(sourceRoot, out);
    const child = spawn('java', ['-jar', process.env.STRUCTURIZR_WAR, 'local', out], {stdio: 'inherit', env: {...process.env, STRUCTURIZR_AUTOREFRESHINTERVAL: '2000', STRUCTURIZR_EDITABLE: 'false', STRUCTURIZR_AUTOSAVEINTERVAL: '0'}});
    let timer;
    const rebuild = () => { try { stage(sourceRoot, out); } catch (e) { console.error('Retaining last valid viewer:', e.message); } };
    const watchers = [sourceRoot, path.join(sourceRoot, 'domain')].map(dir => fs.watch(dir, (event, file) => { if (file?.endsWith('.dsl')) { clearTimeout(timer); timer = setTimeout(rebuild, 250); } }));
    const stop = () => { clearTimeout(timer); watchers.forEach(w => w.close()); child.kill('SIGTERM'); };
    process.on('SIGINT', stop); process.on('SIGTERM', stop);
    child.on('exit', code => { watchers.forEach(w => w.close()); process.exitCode = code || 0; });
    child.on('error', error => { stop(); console.error(error); process.exitCode = 1; });
  } else throw Error('Usage: ontology.mjs export|locate ID|view [--out DIRECTORY] [--source-root ontology]');
}
if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) await main();
