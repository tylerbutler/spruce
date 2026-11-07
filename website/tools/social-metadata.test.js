import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

const site = "https://spruce.tylerbutler.com";

for (const [file, path] of [["index.html", "/"], ["workbench/index.html", "/workbench/"]]) {
  test(`${file} includes static social metadata`, () => {
    const html = readFileSync(new URL(`../${file}`, import.meta.url), "utf8");
    const tags = [...html.matchAll(/<meta\s+(?:property|name)="([^"]+)"\s+content="([^"]*)"\s*\/>/g)];
    const meta = Object.fromEntries(tags.map(([, key, value]) => [key, value]));
    assert.ok(html.includes(`<link rel="canonical" href="${site}${path}" />`));
    assert.equal(meta["og:url"], `${site}${path}`);
    assert.equal(meta["og:site_name"], "spruce");
    assert.equal(meta["og:locale"], "en_US");
    assert.equal(meta["og:type"], "website");
    assert.equal(meta["og:image"], `${site}/og-image.png`);
    assert.equal(meta["og:image:type"], "image/png");
    assert.equal(meta["og:image:width"], "1200");
    assert.equal(meta["og:image:height"], "630");
    assert.equal(meta["twitter:card"], "summary_large_image");
    for (const field of ["title", "description", "image", "image:alt"]) {
      assert.ok(meta[`og:${field}`]?.trim(), `${field} must not be empty`);
      assert.equal(meta[`twitter:${field}`], meta[`og:${field}`]);
    }
    assert.equal(tags.length, new Set(tags.map(([, key]) => key)).size);
  });
}

test("the shared social image is a 1200 x 630 PNG", () => {
  const png = readFileSync(new URL("../public/og-image.png", import.meta.url));
  assert.equal(png.subarray(0, 8).toString("hex"), "89504e470d0a1a0a");
  assert.equal(png.toString("ascii", 12, 16), "IHDR");
  assert.equal(png.readUInt32BE(16), 1200);
  assert.equal(png.readUInt32BE(20), 630);
});
