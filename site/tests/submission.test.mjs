import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { copy } from "../components/copy.ts";

test("listing media has the requested dimensions and no visible contact information", () => {
  for (const [name, width, height] of [["cover", 1920, 1080], ["landing-square", 1080, 1080]]) {
    const png = readFileSync(new URL(`../public/media/${name}.png`, import.meta.url));
    assert.equal(png.subarray(0, 8).toString("hex"), "89504e470d0a1a0a");
    assert.equal(png.readUInt32BE(16), width);
    assert.equal(png.readUInt32BE(20), height);
    const svg = readFileSync(new URL(`../public/media/${name}.svg`, import.meta.url), "utf8");
    const visible = [...svg.matchAll(/<text\b[^>]*>(.*?)<\/text>/gs)].map(match => match[1]).join(" ");
    assert.doesNotMatch(visible, /https?:|www\.|@|wa\.me|\+?880\d{8,}/i);
    assert.match(visible, /OFFLINE-FIRST POINT OF SALE/);
    assert.match(visible, /Flutter/);
    assert.match(visible, /SQLite/);
  }
});

test("both landing languages provide real demo instructions and the same content fields", () => {
  assert.deepEqual(Object.keys(copy.en).sort(), Object.keys(copy.bn).sort());
  for (const locale of [copy.en, copy.bn]) {
    assert.equal(locale.demoSteps.length, 3);
    assert.match(locale.demoSteps[1], /Demo Owner.*1234/);
    assert.match(locale.stackBody, /Flutter/);
    assert.equal(locale.tabs.length, 4);
  }
});
