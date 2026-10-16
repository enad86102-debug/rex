// Official Khronos conformance check, separate from artistic release approval.
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import validator from 'gltf-validator';

export async function validateAsset(file) {
  const stat = await fs.lstat(file);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > 64 * 1024 * 1024) {
    throw new Error('Expected a regular GLB no larger than 64 MiB');
  }
  const bytes = new Uint8Array(await fs.readFile(file));
  const report = await validator.validateBytes(bytes, {
    uri: path.basename(file),
    maxIssues: 1000,
    // Do not resolve URIs from untrusted assets: no filesystem reads or HTTP.
    externalResourceFunction: () => Promise.reject(new Error('External resources disabled')),
  });
  return {
    file,
    validatorVersion: validator.version(),
    errors: report.issues.numErrors,
    warnings: report.issues.numWarnings,
    infos: report.issues.numInfos,
    messages: report.issues.messages,
    structureConformant: report.issues.numErrors === 0,
    releaseApproved: false,
  };
}

async function main(args) {
  const [directory, output] = args;
  if (!directory || !output) throw new Error('Usage: node validate_assets.mjs GLB_DIRECTORY REPORT.json');
  const entries = await fs.readdir(directory, { withFileTypes: true });
  const results = [];
  for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
    if (entry.name.endsWith('.glb') && entry.isFile()) {
      results.push(await validateAsset(path.join(directory, entry.name)));
    }
  }
  if (!results.length) throw new Error('No GLB files found; an empty scan is not a pass');
  await fs.writeFile(output, `${JSON.stringify(results, null, 2)}\n`);
  console.log(JSON.stringify({ scanned: results.length,
    errors: results.reduce((sum, r) => sum + r.errors, 0),
    warnings: results.reduce((sum, r) => sum + r.warnings, 0),
    releaseApproved: false }));
  if (results.some((r) => r.errors > 0)) process.exitCode = 1;
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  main(process.argv.slice(2)).catch(() => {
    console.error('Asset validation failed; verify inputs and report permissions.');
    process.exitCode = 1;
  });
}
