const fs = require("node:fs");
const path = require("node:path");
const { pathToFileURL } = require("node:url");

(async () => {
  const { convertCapturedBlocks } = await import(
    pathToFileURL(path.join(__dirname, "ansi2html.js")).href
  );

  const raw = fs.readFileSync(process.argv[2] ?? 0, "utf8");
  const blocks = convertCapturedBlocks(raw);

  process.stdout.write(JSON.stringify(blocks, null, 2) + "\n");
  process.stderr.write(`blocks: ${Object.keys(blocks).join(", ")}\n`);
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
