import assert from 'node:assert/strict';
import * as fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {execFileSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';

export const BASE = '175e0c59b6a05ead62d29bd851085cd5a3818378';
export const files = ['index', '0_Conventions', '1_Scope', '2_Competency_Questions', '3_Classes', 'controls', 'controller-profiles', '4_Relations', '5_Constraints', '6_Generators', '7_Open_points_for_validation'];
export const slug = s => s.toLowerCase().replace(/[^\p{L}\p{N}_\-\s]/gu, '').replace(/ /g, '-');
export const cells = s => s.trim().slice(1, -1).split(/(?<!\\)\|/).map(s => s.trim());
const num = n => String(n).padStart(3, '0');
function anchors(p, prefix, text) {
  [...text.matchAll(/<a id="([^"]+)"><\/a>/g)].forEach((m, i) => p[prefix + 'anchor.' + num(i + 1)] = m[1]);
}
export const androidAliasTargets = new Map([
  ['android-layout', 'c-landscape-layout-and-fixed-joystick'],
  ['android-response', 'c-movement-response-and-camera-sensitivity'],
  ['android-finger-ownership', 'c-finger-ownership-and-simultaneous-controls'],
  ['android-interruption', 'c-intentional-release-versus-interruption'],
  ['android-panels', 'c-inventory-skills-and-shop-touch-interaction'],
  ['android-first-slice', 'c-first-implementation-scope-and-button-activation'],
  ['android-request-order', 'c-requests-arriving-together'],
  ['android-camera-zoom', 'c-camera-zoom-mapping'],
  ['android-device-scope', 'c-device-switching-and-customization-in-this-slice'],
  ['android-back', 'c-android-back-when-no-panel-is-open'],
]);
export function checkAndroidAliases(locate) {
  const file = path.join('ontology', 'domain', 'controller-profiles.dsl'), lines = fs.readFileSync(file, 'utf8').split('\n');
  const expected = [...androidAliasTargets].map(([alias, locator]) => {
    const line = lines.findIndex(line => line.includes(`= element "${locator}" "SectionNote" {`)) + 1;
    assert.ok(line > 0, 'expected Android rule definition: ' + locator);
    return {alias, file, line, locator};
  });
  const actual = [...androidAliasTargets.keys()].map(alias => ({alias, ...locate('controller-profiles.md#' + alias)}));
  assert.deepEqual(actual, expected, 'all ten standalone Android aliases target their intended following rules');
  return actual;
}
const key = s => s.toLowerCase().replace(/\//g, '-').replace(/[^a-z0-9-]/g, '');
function cell(p, k, value, present = true) {
  p[k + '.state'] = !present ? 'absent-column' : value === undefined ? 'missing-cell' : value === '' ? 'empty-cell' : 'text';
  if (p[k + '.state'] === 'text') p[k + '.text'] = value;
}
function coords(p, prefix, file, start, end) {
  p[prefix + 'source.file'] = file + '.md';
  p[prefix + 'source.start'] = String(start);
  p[prefix + 'source.end'] = String(end);
}
export function baselineDocuments(dir) {
  const texts = new Map(files.map(f => [f, dir ? fs.readFileSync(path.join(dir, f + '.md'), 'utf8') : execFileSync('git', ['show', `${BASE}:ontology/domain/${f}.md`], {encoding: 'utf8'})]));
  if (dir) for (const [f, text] of texts) assert.equal(text, execFileSync('git', ['show', `${BASE}:ontology/domain/${f}.md`], {encoding: 'utf8'}));
  const docs = [];
  for (const [file, text] of texts) {
    const lines = text.split('\n'), records = []; let current, section = 'Overview', note = 0;
    const make = (kind, locator, start, end) => {
      const p = {id: locator, kind, order: String(start), 'source.commit': BASE, 'source.status': 'historical baseline coordinates'};
      coords(p, '', file, start, end);
      const r = {kind, locator, fields: p}; records.push(r); return r;
    };
    for (let i = 0; i < lines.length;) {
      if (!lines[i].trim() || lines[i] === '---') { i++; continue; }
      const h = /^(#{1,6}) (.*)$/.exec(lines[i]);
      if (h) {
        if (current) current.fields['source.end'] = String(i);
        const isClass = file === '3_Classes' && h[1] === '###' && !/^3\./.test(h[2]);
        if (/^3\.\d /.test(h[2])) section = h[2].split(' ').slice(1).join('');
        current = make(isClass ? 'Class' : 'SectionNote', isClass ? h[2].split(' ')[0] : `${file === 'index' ? 'index' : file[0]}-${slug(h[2])}`, i + 1, lines.length);
        Object.assign(current.fields, {title: h[2], 'heading.level': String(h[1].length), 'heading.slug': slug(h[2]), section});
        note = 0; i++; continue;
      }
      assert.ok(current, file + ':' + (i + 1));
      const p = current.fields, n = 'note.' + num(++note) + '.', start = i;
      if (lines[i].startsWith('|') && /^\|[-:| ]+\|$/.test(lines[i + 1] || '')) {
        const columns = cells(lines[i]); i += 2; const rows = [];
        while (lines[i]?.startsWith('|')) { rows.push({line: i + 1, values: cells(lines[i])}); i++; }
        const catalog = ({'2_Competency_Questions': 'Question', '4_Relations': 'RelationDefinition', '5_Constraints': 'Constraint', '6_Generators': 'Generator'})[file];
        const isCatalog = catalog && ['id', '#'].includes(columns[0]);
        const property = current.kind === 'Class' && ['prop', 'rule'].includes(columns[0]);
        const prefix = property ? 'property.' : n;
        p[n + 'kind'] = property ? 'property-table' : isCatalog ? 'catalog-table' : 'table';
        columns.forEach((c, j) => p[prefix + 'column.' + num(j + 1) + '.text'] = c);
        for (let j = 0; j < rows.length; j++) {
          const row = rows[j], rp = prefix + 'row.' + num(j + 1) + '.';
          if (isCatalog) {
            const id = row.values[0].split(' ')[0].toLowerCase();
            const r = make(catalog, id, row.line, row.line);
            p[n + 'row.' + num(j + 1) + '.target'] = id;
            const names = {Question: ['label', 'question', 'answered-by'], RelationDefinition: ['id', 'domain', 'range', 'cardinality', 'meaning'], Constraint: ['id', 'rule', 'layer'], Generator: ['display', 'input', 'output', 'invariants']}[catalog];
            names.forEach((name, k) => { if (name !== 'id') cell(r.fields, name, row.values[k]); });
          } else if (property) {
            const pr = 'property.' + num(j + 1) + '.';
            p[pr + 'name'] = row.values[0]; coords(p, pr, file, row.line, row.line);
            for (const c of ['type', 'i-e', 'notes', 'value']) { const index = columns.findIndex(x => key(x) === c); cell(p, pr + c, index < 0 ? undefined : row.values[index], index >= 0); }
          } else {
            coords(p, rp, file, row.line, row.line);
            anchors(p, rp, row.values.join(' | '));
            columns.forEach((c, k) => cell(p, rp + 'cell.' + num(k + 1), row.values[k]));
          }
        }
      } else {
        let kind = lines[i].startsWith('```') ? 'code' : /^\s*- /.test(lines[i]) ? 'list' : lines[i].startsWith('[^') ? 'footnote' : 'paragraph';
        p[n + 'kind'] = kind;
        if (kind === 'code') { i++; while (i < lines.length && !lines[i].startsWith('```')) i++; assert.ok(i < lines.length); i++; }
        else { i++; while (i < lines.length && lines[i].trim() && !/^(#|\||```|---)/.test(lines[i])) i++; }
        lines.slice(start, i).forEach((line, j) => cell(p, n + 'line.' + num(j + 1), line));
        anchors(p, n, lines.slice(start, i).join('\n'));
      }
      coords(p, n, file, start + 1, i);
    }
    if (current) current.fields['source.end'] = String(lines.length - 1);
    docs.push({file: file + '.dsl', records});
  }
  const all = docs.flatMap(d => d.records), ids = new Set(all.map(r => r.locator));
  for (const r of all) {
    if (r.kind === 'RelationDefinition') for (const side of ['domain', 'range']) {
      r.fields[side + '.text'].split(' ∪ ').forEach((part, i) => {
        const m = /^([a-z-]+)\s*(.*)$/.exec(part); assert.ok(m, part);
        r.fields[`${side}.member.${num(i + 1)}.symbol`] = m[1];
        cell(r.fields, `${side}.member.${num(i + 1)}.qualifier`, m[2]);
      });
    }
    if (r.kind === 'Question') [...r.fields['answered-by.text'].matchAll(/`([^`]+)`/g)].forEach((m, i) => {
      const token = m[1], kind = ids.has(token) ? 'declared-record' : /\.json/.test(token) ? 'file-reference' : 'unresolved-source-term';
      Object.assign(r.fields, {[`answer-reference.${num(i + 1)}.token`]: token, [`answer-reference.${num(i + 1)}.kind`]: kind, [`answer-reference.${num(i + 1)}.target`]: token});
    });
    if (r.locator === 'threat') Object.assign(r.fields, {'relation-property.001.name': 'aggro-points', 'relation-property.001.type': 'numeric', 'relation-property.001.minimum': '0', 'relation-property.001.units': 'aggro points', 'relation-property.001.cardinality': 'exactly one per present ordered logical pair'});
  }
  return docs;
}
// Exact status-only reconciliation to master's later 110b7cd hardware report, not new acceptance claims.
const statusCorrections = {
  '3_Classes.dsl': [['are selected but unimplemented.', 'have a bounded first-slice runtime, owner hardware-tested; detailed coverage and render cost remain unrecorded.']],
  'controls.dsl': [['have a first-slice runtime; physical', 'have a first-slice runtime, owner hardware-tested; detailed coverage and render cost are unrecorded.'], ['Android acceptance and broader catalog implementation remain pending.', 'Broader catalog implementation remains deferred.']],
};
const currentStatus = (text, file) => (statusCorrections[file.replace('.md', '.dsl')] || []).reduce((text, [before, after]) => text.replace(before, after), text);
export function compareDocuments(a, b) {
  assert.equal(b.length, a.length, 'chapter count');
  for (let d = 0; d < a.length; d++) {
    assert.equal(b[d].file, a[d].file, 'chapter');
    assert.equal(b[d].records.length, a[d].records.length, a[d].file + ': record count');
    for (let r = 0; r < a[d].records.length; r++) {
      const expected = a[d].records[r], actual = b[d].records[r], label = a[d].file + ':' + expected.locator;
      assert.equal(actual.kind, expected.kind, label); assert.equal(actual.locator, expected.locator, label);
      assert.equal(Object.keys(actual.fields).length, Object.keys(expected.fields).length, label + ': field count');
      for (const k of Object.keys(expected.fields)) assert.equal(actual.fields[k], expected.fields[k], label + ':' + k);
    }
  }
}
export function inventory(docs) {
  const all = docs.flatMap(d => d.records), counts = ['Class', 'RelationDefinition', 'Constraint', 'Generator', 'Question'].map(k => all.filter(r => r.kind === k).length);
  assert.deepEqual(counts, [86, 55, 73, 19, 19]);
  let props = 0, rules = 0, tables = 0, missing = 0;
  for (const r of all.filter(r => r.kind === 'Class')) {
    const p = r.fields, rows = Object.keys(p).filter(k => /^property\.\d+\.name$/.test(k));
    if (rows.length) { tables++; if (p['property.column.001.text'] === 'rule') rules += rows.length; else props += rows.length; }
    missing += Object.entries(p).filter(([k,v]) => /^property\.\d+\.notes.state$/.test(k) && v === 'missing-cell').length;
  }
  assert.deepEqual([props, rules, tables, missing], [192, 11, 25, 5]);
  return {counts, props, rules, tables, missing};
}
function checkInlineSections(line, label) {
  for (const match of line.matchAll(/(?:index|([0-7])_[A-Za-z_]+)\.dsl[ \t]+(§[0-7](?:\.\d+)*(?:\/§?[0-7](?:\.\d+)*)*)/g)) {
    if (match[1] === undefined) continue; // The index includes every chapter.
    for (const section of match[2].split('/')) assert.equal(section.replace('§', '')[0], match[1], 'inline section/file mismatch ' + label + ': ' + match[0]);
  }
}
async function main() {
  checkInlineSections('index.dsl §0/§5; 3_Classes.dsl §3.4; 5_Constraints.dsl §5', 'positive');
  for (const [chapter, sections] of [['0_Conventions', '§0/§5'], ['3_Classes', '§3.4/§5'], ['3_Classes', '§3.4/5']]) assert.throws(() => checkInlineSections(chapter + '.dsl ' + sections, 'mutation'), /inline section\/file mismatch/);
  const arg = name => process.argv.includes(name) ? process.argv[process.argv.indexOf(name) + 1] : undefined;
  const expected = baselineDocuments(arg('--baseline-dir'));
  console.log('baseline inventory', inventory(expected));
  for (const d of expected) {
    const original = execFileSync('git', ['show', `${BASE}:ontology/domain/${d.file.replace('.dsl', '.md')}`], {encoding: 'utf8'}).split('\n');
    const ledger = new Map();
    const mark = line => ledger.set(line, (ledger.get(line) || 0) + 1);
    for (const r of d.records.filter(r => r.fields.title)) {
      mark(+r.fields['source.start']);
      for (const k of Object.keys(r.fields).filter(k => /^note\.\d+\.source.start$/.test(k))) for (let i = +r.fields[k]; i <= +r.fields[k.replace('.start', '.end')]; i++) mark(i);
    }
    original.forEach((line, i) => { if (line.trim() && line !== '---') assert.equal(ledger.get(i + 1), 1, d.file + ':' + (i + 1) + ' exact-once source coverage'); });
    assert.ok([...ledger.values()].every(n => n === 1), 'overlapping source blocks');
  }
  assert.deepEqual(cells('| kind | kingdom \\| realm | |'), ['kind', 'kingdom \\| realm', '']);
  assert.equal(slug('region-lock `S` — **DROPPED (D4)**'), 'region-lock-s--dropped-d4');
  if (process.argv.includes('--baseline-only')) return;
  assert.ok(fs.existsSync('ontology/workspace.dsl'), 'canonical DSL entry is missing');
  const {documentsFromWorkspace, renderDocuments, locate} = await import('./ontology.mjs');
  const workspace = JSON.parse(fs.readFileSync(arg('--workspace-json'), 'utf8'));
  const actual = documentsFromWorkspace(workspace);
  const elements = workspace.model.customElements;
  assert.deepEqual(elements.filter(e => e.metadata === 'EndpointTerm').map(e => e.properties.id).sort(), ['dungeon', 'elixir', 'hazard', 'magic-crystal', 'mechanic', 'poi']);
  assert.ok(elements.flatMap(e => e.relationships || []).every(edge => edge.sourceId !== edge.destinationId), 'no native self-loops');
  for (const kind of ['incidence', 'answer']) {
    const damaged = structuredClone(workspace);
    const element = damaged.model.customElements.find(e => e.relationships?.some(edge => edge.description === (kind === 'answer' ? 'answered by' : 'domain member')));
    element.relationships.splice(element.relationships.findIndex(edge => edge.description === (kind === 'answer' ? 'answered by' : 'domain member')), 1);
    assert.throws(() => documentsFromWorkspace(damaged), kind + ' edge removal rejected');
  }
  {
    const damaged = structuredClone(workspace), e = damaged.model.customElements.find(e => e.relationships?.length);
    e.relationships.push({...structuredClone(e.relationships[0]), id: 'unapproved-edge', description: 'inherits'});
    assert.throws(() => documentsFromWorkspace(damaged), /Undeclared\/implied/);
  }
  for (const mutation of ['state', 'unknown', 'duplicate']) {
    const damaged = structuredClone(workspace), e = damaged.model.customElements.find(e => e.properties.kind === 'Class');
    if (mutation === 'unknown') e.metadata = 'InventedClass';
    else if (mutation === 'duplicate') damaged.model.customElements.push(structuredClone(e));
    else delete e.properties[Object.keys(e.properties).find(k => k.endsWith('.state'))];
    assert.throws(() => documentsFromWorkspace(damaged), mutation + ' rejected');
  }
  // Independently verify every permitted link substitution against actual source locators.
  const rewriteLinks = (text, file) => text.replace(/\[([^\]]+)\]\(([^)#]*)(?:#([^)]*))?\)/g, (full, caption, target, fragment) => {
    const name = target || file.replace('.dsl', '.md');
    if (!files.includes(name.replace('.md', ''))) return full;
    if (fragment) locate(name + '#' + fragment);
    return `[${caption}${fragment ? ' (locator=' + fragment + ')' : ''}](${name.replace('.md', '.dsl')})`;
  });
  for (const d of expected) for (const r of d.records) for (const k of Object.keys(r.fields)) if (k.endsWith('.text')) r.fields[k] = rewriteLinks(currentStatus(r.fields[k], d.file), d.file);
  compareDocuments(expected, actual);
  inventory(actual);
  for (const d of expected) for (const r of d.records) if (r.fields['heading.slug']) {
    const found = locate(d.file.replace('.dsl', '.md') + '#' + r.fields['heading.slug']); assert.ok(found.line > 0);
  }
  const androidAliases = checkAndroidAliases(locate), actionAnchors = [];
  for (const d of expected) for (const r of d.records) for (const [k, anchor] of Object.entries(r.fields)) if (/^note\.\d+\.(?:row\.\d+\.)?anchor\.\d+$/.test(k)) {
    const target = /\.row\./.test(k) ? r.locator : androidAliasTargets.get(anchor);
    assert.ok(target, 'known standalone alias: ' + anchor);
    if (!/\.row\./.test(k)) {
      const prefix = k.replace(/anchor\.\d+$/, '');
      assert.equal(r.fields[prefix + 'line.001.text'], `<a id="${anchor}"></a>`, 'standalone source alias');
      assert.equal(+r.fields[prefix + 'source.end'] + 1, +d.records.find(r => r.locator === target).fields['source.start'], 'alias immediately precedes intended heading');
    }
    assert.equal(locate(d.file.replace('.dsl', '.md') + '#' + anchor).locator, target);
    if (d.file === 'controls.dsl') actionAnchors.push(anchor);
  }
  assert.equal(actionAnchors.length, 54); assert.equal(new Set(actionAnchors).size, 54);
  assert.equal(locate('block').locator, 'block');
  assert.equal(locate('controls.md#block').locator, 'c-combat-and-class-skills', 'table-row anchor stays with its table, not the terrain class or following section');
  assert.throws(() => locate('controller-profiles.md#android-invented'), /Unknown\/ambiguous/);
  const canonical = actual; let mutations = 0;
  // Every authored leaf, record and chapter is mutation-tested, not just sentinel counts.
  for (let d = 0; d < canonical.length; d++) {
    const removed = structuredClone(canonical); removed.splice(d, 1); assert.throws(() => compareDocuments(expected, removed)); mutations++;
    for (let r = 0; r < canonical[d].records.length; r++) {
      const deleted = structuredClone(canonical); deleted[d].records.splice(r, 1); assert.throws(() => compareDocuments(expected, deleted)); mutations++;
      for (const k of Object.keys(canonical[d].records[r].fields)) {
        const fields = canonical[d].records[r].fields, original = fields[k];
        fields[k] += ' MUTATED'; assert.throws(() => compareDocuments(expected, canonical)); fields[k] = original; mutations++;
      }
    }
  }
  for (const [locator, prefix] of [['world', 'property.001.'], ['world', 'note.002.'], ['threat', 'domain.member.001.qualifier.'], ['threat', 'relation-property.001.'], ['cq1', 'answer-reference.001.']]) {
    const damaged = structuredClone(canonical), fields = damaged.flatMap(d => d.records).find(r => r.locator === locator).fields;
    for (const k of Object.keys(fields)) if (k.startsWith(prefix)) delete fields[k];
    assert.throws(() => compareDocuments(expected, damaged), 'deleted property/note/role/relation property/CQ reference group: ' + locator + ':' + prefix);
  }
  const rendered = renderDocuments(actual);
  assert.equal(rendered.size, files.length);
  const nativeDocs = renderDocuments(actual, true);
  for (const chapter of ['controls', 'controller-profiles']) assert.ok(nativeDocs.get(chapter + '.md').includes('\n## ' + (chapter === 'controls' ? 'Controls' : 'Controller profiles') + '\n'), 'native chapter navigation: ' + chapter);
  assert.ok(nativeDocs.get('controller-profiles.md').includes('\n#### Movement response and camera sensitivity\n'), 'native subsection depth');
  const native = [...nativeDocs.values()].join('\n');
  assert.equal(native.split('_missing source cell_').length - 1, 5, 'native viewer distinguishes all five omitted source cells from explicit blanks');
  // Independent full normalized Markdown round trip: every meaningful line/cell, not counts.
  function normalized(text) {
    let code = false;
    return text.split('\n').flatMap(line => {
      if (line.startsWith('```')) { code = !code; return [line]; }
      if (code) return [line];
      if (!line.trim() || line === '---' || /^\|[-:| ]+\|$/.test(line) || line.startsWith('> GENERATED')) return [];
      return [line.startsWith('|') ? JSON.stringify(cells(line)) : line.trimEnd()];
    });
  }
  for (const [file, text] of rendered) {
    const original = execFileSync('git', ['show', `${BASE}:ontology/domain/${file}`], {encoding: 'utf8'});
    assert.deepEqual(normalized(text), normalized(rewriteLinks(currentStatus(original, file), file)), 'full normalized round trip: ' + file);
  }
  const out = arg('--evidence-dir');
  if (out) { fs.mkdirSync(out, {recursive: true}); for (const [f, text] of rendered) fs.writeFileSync(path.join(out, f), text); }
  if (!process.argv.includes('--allow-original-markdown')) assert.equal(fs.readdirSync('ontology/domain').filter(f => f.endsWith('.md')).length, 0, 'authoritative Markdown remains');
  // Runtime/catalog scope and all current incoming domain references, including inline paths.
  const tracked = execFileSync('git', ['ls-files', '-z'], {encoding: 'utf8'}).split('\0').filter(Boolean);
  // Only exact reference spans from immutable master may change: all other values/keys stay exact.
  const chapterPattern = '(?:' + files.join('|') + ')';
  const numbered = ['0_Conventions', '1_Scope', '2_Competency_Questions', '3_Classes', '4_Relations', '5_Constraints', '6_Generators', '7_Open_points_for_validation'];
  const substitutions = text => {
    text = text.replace(/\[([^\]]+)\]\(([^)#]+)(?:#([^)]*))?\)/g, (full, caption, target, fragment) => {
      if (!files.includes(path.basename(target, '.md')) || !target.endsWith('.md')) return full;
      if (fragment) locate(path.basename(target) + '#' + fragment);
      return `[${caption}${fragment ? ' (locator=' + fragment + ')' : ''}](${target.replace(/\.md$/, '.dsl')})`;
    });
    text = text.replace(/((?:ontology\/)?domain\/)index\.md( §([0-7])(?:\.[1-7])?)?/g, (full, prefix, section, n) => prefix + (n ? numbered[+n] : 'index') + '.dsl' + (section || ''));
    return text.replace(new RegExp('((?:ontology/)?domain/)(' + chapterPattern + ')\\.md(?:#([a-z0-9_-]+))?', 'g'), (full, prefix, chapter, fragment) => {
      if (fragment) locate(chapter + '.md#' + fragment);
      return prefix + chapter + '.dsl' + (fragment ? ' (locator=' + fragment + ')' : '');
    });
  };
  let referenceLeaves = 0;
  function relocateCatalog(value) {
    if (typeof value === 'string') { const moved = substitutions(value); if (moved !== value) referenceLeaves++; return moved; }
    if (Array.isArray(value)) return value.map(relocateCatalog);
    if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k,v]) => [k, relocateCatalog(v)]));
    return value;
  }
  for (const file of tracked.filter(f => f.startsWith('ontology/instances/') && f.endsWith('.json'))) {
    const old = JSON.parse(execFileSync('git', ['show', `${BASE}:${file}`], {encoding: 'utf8'}));
    const expected = relocateCatalog(old), current = JSON.parse(fs.readFileSync(file, 'utf8'));
    assert.deepEqual(current, expected, 'catalog unchanged except exact immutable-source reference spans: ' + file);
    const damaged = structuredClone(current); damaged.__unapproved = 1; assert.notDeepEqual(damaged, expected);
  }
  assert.equal(referenceLeaves, 115, 'finite immutable-source JSON reference allowlist');
  const generators = JSON.parse(fs.readFileSync('ontology/instances/generators.json', 'utf8'));
  const numericMutation = structuredClone(generators); numericMutation.design.camera.distance.step++;
  assert.notDeepEqual(numericMutation, generators, 'nonreference numeric change rejected');
  const missingUIDs = ['game/entities/test_android_controls.gd.uid', 'game/meta/android_touch.gd.uid', 'game/meta/test_android_touch.gd.uid', 'ontology/test_android_profile.gd.uid'];
  const androidBefore = `\tvar controls := FileAccess.get_file_as_string("res://ontology/domain/controls.md")`;
  const androidAfter = `\tvar controls := FileAccess.get_file_as_string("res://ontology/domain/controls.dsl")
\tvar anchors := RegEx.new()
\tanchors.compile('"note\\\\.\\\\d+\\\\.row\\\\.\\\\d+\\\\.anchor\\\\.\\\\d+" "([^"\\\\\\\\]+)"')
\tvar canonical: Array[String] = []
\tfor match in anchors.search_all(controls):
\t\tcanonical.append(match.get_string(1))
\tcheck(canonical.size() == 54, "complete canonical action anchors")`;
  for (const file of tracked.filter(f => f.startsWith('game/') || /\.(gd|tscn|tres)$/.test(f))) {
    const after = fs.readFileSync(file);
    if (missingUIDs.includes(file)) { assert.match(after.toString(), /^uid:\/\/[a-z0-9]+\n$/); continue; }
    const before = execFileSync('git', ['show', `${BASE}:${file}`]);
    if (before.equals(after)) continue;
    if (file === 'ontology/test_android_profile.gd') {
      assert.equal(after.toString(), before.toString().replace(androidBefore, androidAfter).replace(`('id="%s"' % action) in controls`, 'canonical.count(action) == 1'), 'only canonical source-format lookup changes');
    } else {
      assert.ok(['game/world/world_gen.gd', 'ontology/model.gd', 'ontology/validate.gd', 'game/README.md'].includes(file), 'unexpected runtime diff ' + file);
      assert.equal(after.toString(), substitutions(before.toString()), 'source-reference-only: ' + file);
    }
  }
  const currentFiles = [...tracked, ...execFileSync('git', ['ls-files', '--others', '--exclude-standard', '-z'], {encoding: 'utf8'}).split('\0').filter(Boolean)];
  for (const file of new Set(currentFiles)) {
    if (!fs.existsSync(file) || fs.lstatSync(file).isSymbolicLink()) continue;
    const text = fs.readFileSync(file, 'utf8'); if (text.includes('\0')) continue;
    for (const [i, line] of text.split('\n').entries()) {
      checkInlineSections(line, file + ':' + (i + 1));
      if (file.endsWith('.dsl') && /"(?:.*\.)?source.file"/.test(line)) continue; // Explicitly historical source coordinates.
      if (file === 'tools/test_ontology.mjs' && line.includes('const androidBefore =')) continue; // Exact immutable-master input for the format-only regression adaptation.
      if (file === 'ontology/README.md' && line.includes("locate '3_Classes.md#skill-tree-a'")) continue; // Historical-locator command example.
      assert.ok(!/(?:domain\/|\]\()(?:index|[0-7]_[A-Za-z_]+|controls|controller-profiles)\.md/.test(line), 'old live authority reference ' + file + ':' + (i + 1));
      assert.ok(!/\.dsl#[a-z0-9-]+/.test(line), 'fake DSL fragment ' + file + ':' + (i + 1));
      for (const match of line.matchAll(/\[([^\]]+)\]\(([^)]+\.dsl)\)/g)) {
        const base = file.endsWith('.dsl') ? 'ontology/domain' : path.dirname(file);
        assert.ok(fs.existsSync(path.resolve(base, match[2])), 'broken DSL file link ' + file + ':' + (i + 1));
        const fragment = /\(locator=([^)]*)\)/.exec(match[1]);
        if (fragment) locate(path.basename(match[2]).replace('.dsl', '.md') + '#' + fragment[1]);
      }
    }
  }
  assert.throws(() => locate('3_Classes.md#skill-tree'), /Unknown\/ambiguous/, 'versioned heading must not silently resolve an invented slug');
  assert.throws(() => locate('3_Classes.md#broken-versioned-heading'), /Unknown\/ambiguous/);
  assert.equal(execFileSync('git', ['check-ignore', '.structurizr/workspace.json'], {encoding: 'utf8'}).trim(), '.structurizr/workspace.json');
  if (process.argv.includes('--viewer-check')) {
    const {stage} = await import('./ontology.mjs');
    const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'ontology-regression-'));
    try {
      const source = path.join(temp, 'source'), out = path.join(temp, 'viewer'); fs.mkdirSync(source);
      fs.copyFileSync('ontology/workspace.dsl', path.join(source, 'workspace.dsl'));
      fs.cpSync('ontology/domain', path.join(source, 'domain'), {recursive: true});
      fs.mkdirSync(out); // An explicitly empty destination is safe to initialize.
      stage(source, out);
      fs.writeFileSync(path.join(out, 'workspace.json'), '{}'); // Native local's own output is retained, not overwritten.
      const runtime = path.join(out, '.structurizr');
      fs.mkdirSync(path.join(runtime, 'logs'), {recursive: true});
      fs.writeFileSync(path.join(runtime, 'logs', 'structurizr.log'), 'native runtime log');
      stage(source, out); // An owned, unmodified stage is safe to rebuild with native runtime files present.
      assert.equal(fs.readFileSync(path.join(out, 'workspace.json'), 'utf8'), '{}');
      assert.equal(fs.readFileSync(path.join(runtime, 'logs', 'structurizr.log'), 'utf8'), 'native runtime log');
      const tree = dir => fs.readdirSync(dir).sort().flatMap(name => {
        const filename = path.join(dir, name), stat = fs.lstatSync(filename);
        if (stat.isSymbolicLink()) return [[filename, 'link', fs.readlinkSync(filename)]];
        return stat.isDirectory() ? [[filename, 'dir'], ...tree(filename)] : [[filename, fs.readFileSync(filename).toString('base64')]];
      });
      const wrapperPath = path.join(out, 'workspace.dsl'), wrapperBytes = fs.readFileSync(wrapperPath);
      const unexpected = path.join(out, 'docs', 'sentinel');
      for (const mutation of ['extra-file', 'extra-directory', 'edited-wrapper', 'symlink-wrapper', 'symlink-docs', 'hardlink-wrapper', 'runtime-symlink']) {
        if (mutation === 'extra-file') fs.writeFileSync(unexpected, 'do not delete');
        if (mutation === 'extra-directory') fs.mkdirSync(unexpected);
        if (mutation === 'edited-wrapper') fs.appendFileSync(wrapperPath, '\n// personal edit');
        if (mutation === 'symlink-wrapper') { fs.unlinkSync(wrapperPath); fs.symlinkSync(path.join(source, 'workspace.dsl'), wrapperPath); }
        if (mutation === 'symlink-docs') { fs.renameSync(path.join(out, 'docs'), path.join(temp, 'saved-docs')); fs.symlinkSync(path.join(temp, 'saved-docs'), path.join(out, 'docs')); }
        if (mutation === 'hardlink-wrapper') fs.linkSync(wrapperPath, path.join(temp, 'linked-wrapper'));
        if (mutation === 'runtime-symlink') fs.symlinkSync(source, path.join(runtime, 'alias'));
        const before = tree(temp);
        assert.throws(() => stage(source, out), /Unsafe viewer destination/, mutation);
        assert.deepEqual(tree(temp), before, mutation + ' rejection preserves all files and creates no build sibling');
        const cli = (() => { try { execFileSync(process.execPath, ['tools/ontology.mjs', 'view', '--source-root', source, '--out', out], {stdio: 'pipe'}); } catch (error) { return error; } })();
        assert.ok(cli && cli.status !== 0); assert.match(cli.stderr.toString(), /Unsafe viewer destination/);
        assert.deepEqual(tree(temp), before, mutation + ' CLI rejection preserves all files');
        if (mutation.startsWith('extra-')) fs.rmSync(unexpected, {recursive: true});
        if (mutation === 'symlink-docs') { fs.unlinkSync(path.join(out, 'docs')); fs.renameSync(path.join(temp, 'saved-docs'), path.join(out, 'docs')); }
        if (mutation === 'hardlink-wrapper') fs.unlinkSync(path.join(temp, 'linked-wrapper'));
        if (mutation === 'runtime-symlink') fs.unlinkSync(path.join(runtime, 'alias'));
        if (mutation === 'symlink-wrapper') fs.unlinkSync(wrapperPath);
        fs.writeFileSync(wrapperPath, wrapperBytes);
      }
      const saved = fs.readFileSync(path.join(out, 'workspace.dsl'));
      const docs = fs.readdirSync(path.join(out, 'docs')); assert.equal(docs.length, files.length);
      for (const doc of docs) {
        const filename = path.join(out, 'docs', doc), text = fs.readFileSync(filename, 'utf8');
        assert.equal(fs.statSync(filename).mode & 0o222, 0, 'generated docs read-only');
        assert.ok(text.startsWith('> GENERATED')); assert.ok(!/\]\([^)]*\.dsl/.test(text), 'native docs have no unservable DSL links');
        for (const target of androidAliases) for (const line of text.split('\n').filter(line => line.includes('(locator=' + target.alias + ')'))) {
          assert.ok(line.includes(`controller-profiles.dsl:${target.line}; id=${target.locator}`), 'native locator identifies intended rule: ' + target.alias);
        }
      }
      fs.appendFileSync(path.join(source, 'workspace.dsl'), '\ninvalid_keyword\n');
      assert.throws(() => stage(source, out), /Unexpected tokens/);
      assert.ok(saved.equals(fs.readFileSync(path.join(out, 'workspace.dsl'))), 'failed parse retains valid staged wrapper');
      fs.copyFileSync('ontology/workspace.dsl', path.join(source, 'workspace.dsl'));
      const filename = path.join(source, 'domain', '0_Conventions.dsl');
      fs.writeFileSync(filename, fs.readFileSync(filename, 'utf8').replace('properties {', 'properties {\n        "id" "duplicate"'));
      assert.throws(() => stage(source, out), /Duplicate authored property/);
      assert.ok(saved.equals(fs.readFileSync(path.join(out, 'workspace.dsl'))));
      console.log('PASS empty/owned real-parser staging; retained native runtime files; seven ownership/alias/hardlink mutations rejected by stage + CLI without writes; eleven read-only docs; malformed DSL/duplicate-property negatives retain last valid stage');
    } finally { fs.rmSync(temp, {recursive: true, force: true}); }
  }
  assert.equal(execFileSync('git', ['diff', '--cached', '--name-only'], {encoding: 'utf8'}), '', 'index must remain unstaged');
  console.log(`PASS full official-export parity; ${mutations} leaf/record/chapter mutations rejected; exact-once coverage; eleven full normalized chapter round trips; all historical headings locate; incidence/answer negatives; current-reference/runtime/catalog scope; no staged files`);
}
if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) await main();
