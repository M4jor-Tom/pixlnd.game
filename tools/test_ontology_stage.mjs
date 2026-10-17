// Disposable fixtures only: never exercise rejected destinations against a real checkout.
import assert from 'node:assert/strict';
import * as fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';

const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'ontology-stage-safety-'));
try {
  const repo = path.join(temp, 'repo'), source = path.join(repo, 'ontology');
  fs.mkdirSync(path.join(repo, 'tools'), {recursive: true});
  fs.mkdirSync(source);
  fs.writeFileSync(path.join(source, 'sentinel.dsl'), 'canonical source');
  fs.mkdirSync(path.join(repo, 'docs'));
  fs.writeFileSync(path.join(repo, 'docs', 'sentinel.md'), 'repository documentation');
  const helper = path.join(repo, 'tools', 'ontology.mjs');
  fs.copyFileSync(new URL('./ontology.mjs', import.meta.url), helper);
  const {stage} = await import(pathToFileURL(helper));
  const outside = path.join(temp, 'external-source'); fs.mkdirSync(outside);
  fs.writeFileSync(path.join(outside, 'sentinel.dsl'), 'external canonical source');
  const unowned = path.join(temp, 'unowned'); fs.mkdirSync(unowned);
  fs.writeFileSync(path.join(unowned, 'sentinel'), 'do not touch');
  const fake = path.join(temp, 'fake-owner'); fs.mkdirSync(fake);
  fs.writeFileSync(path.join(fake, '.ontology-stage.json'), '{}');
  const alias = path.join(temp, 'alias'); fs.symlinkSync(source, alias);
  const outputAlias = path.join(temp, 'output-alias'); fs.symlinkSync(unowned, outputAlias);
  const snapshot = dir => fs.readdirSync(dir).sort().flatMap(name => {
    const filename = path.join(dir, name), stat = fs.lstatSync(filename);
    if (stat.isSymbolicLink()) return [[filename, 'link', fs.readlinkSync(filename)]];
    return stat.isDirectory() ? [[filename, 'dir'], ...snapshot(filename)] : [[filename, fs.readFileSync(filename).toString('base64')]];
  });
  const cases = [
    [source, repo], [source, temp], [source, source], [source, path.join(source, 'new', 'viewer')],
    [outside, repo], // Repository protection is independent of the chosen source root.
    [source, alias], [source, path.join(alias, 'new-viewer')], [source, outputAlias],
    [source, unowned], [source, fake], [source, path.join(repo, 'docs')],
  ];
  for (const [input, out] of cases) {
    const before = snapshot(temp);
    assert.throws(() => stage(input, out), /Unsafe viewer destination/, 'direct stage rejection: ' + out);
    assert.deepEqual(snapshot(temp), before, 'direct rejection changed files or created temporary siblings');
    const cli = spawnSync(process.execPath, [helper, 'view', '--source-root', input, '--out', out], {encoding: 'utf8'});
    assert.notEqual(cli.status, 0);
    assert.match(cli.stderr, /Unsafe viewer destination/, 'CLI uses shared safety boundary');
    assert.deepEqual(snapshot(temp), before, 'CLI rejection changed files or created temporary siblings');
  }
  console.log(`PASS ${cases.length} disposable destination cases, direct stage + CLI; all sentinels/trees unchanged, no output/build siblings`);
} finally { fs.rmSync(temp, {recursive: true, force: true}); }
