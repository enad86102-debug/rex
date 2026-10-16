import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { validateAsset } from './validate_assets.mjs';

function glb(document) {
  let json = Buffer.from(JSON.stringify(document));
  const pad = (4 - json.length % 4) % 4;
  json = Buffer.concat([json, Buffer.alloc(pad, 0x20)]);
  const header = Buffer.alloc(20);
  header.write('glTF'); header.writeUInt32LE(2, 4);
  header.writeUInt32LE(20 + json.length, 8);
  header.writeUInt32LE(json.length, 12); header.write('JSON', 16);
  return Buffer.concat([header, json]);
}

test('official validator rejects broken buffers that shallow JSON intake accepts', async (t) => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'rex-gltf-'));
  t.after(() => fs.rm(dir, { recursive: true, force: true }));
  const file = path.join(dir, 'broken.glb');
  await fs.writeFile(file, glb({ asset: { version: '2.0' }, buffers: [{ byteLength: 128 }] }));
  const report = await validateAsset(file);
  assert.ok(report.errors > 0);
  assert.equal(report.releaseApproved, false);
});

test('structurally valid GLB never automatically receives art or release approval', async (t) => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'rex-gltf-'));
  t.after(() => fs.rm(dir, { recursive: true, force: true }));
  const file = path.join(dir, 'empty.glb');
  await fs.writeFile(file, glb({ asset: { version: '2.0' } }));
  const report = await validateAsset(file);
  assert.equal(report.errors, 0);
  assert.equal(report.structureConformant, true);
  assert.equal(report.releaseApproved, false);
});

test('untrusted external resources are rejected without reading local files', async (t) => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'rex-gltf-'));
  t.after(() => fs.rm(dir, { recursive: true, force: true }));
  const file = path.join(dir, 'external.glb');
  await fs.writeFile(file, glb({ asset: { version: '2.0' }, buffers: [{ byteLength: 16, uri: 'file:///etc/passwd' }] }));
  const report = await validateAsset(file);
  assert.ok(report.errors > 0);
});
