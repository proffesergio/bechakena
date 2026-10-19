import assert from "node:assert/strict";
import test from "node:test";
import { formatPreviewMoney, inclusiveTaxMinor, previewCurrencies, replenishmentPreview } from "../lib/preview.ts";

test("inclusive tax reconciles a sample receipt to the minor unit", () => {
  assert.equal(inclusiveTaxMinor(30000, 1500), 3913);
  assert.equal(inclusiveTaxMinor(30000, 0), 0);
  assert.equal(inclusiveTaxMinor(30000, 2000), 5000);
  assert.equal(inclusiveTaxMinor(1, 10000), 1);
});

test("every currency preview preserves the POS's two-decimal amounts without conversion", () => {
  for (const currency of previewCurrencies) {
    assert.equal(formatPreviewMoney(12550, currency, "en-US"), `${currency}\u00a0125.50`, currency);
    assert.equal(formatPreviewMoney(30000, currency, "en-US"), `${currency}\u00a0300.00`, currency);
  }
  assert.match(formatPreviewMoney(12550, "BDT", "bn-BD"), /১২৫\.৫০/);
});

test("replenishment explains cover, rounds up partial demand and never orders negative stock", () => {
  assert.deepEqual(replenishmentPreview(84, 12, 3, 7), { dailyDemand: 3, daysCover: 4, targetStock: 30, suggestedOrder: 18 });
  assert.equal(replenishmentPreview(1, 0, 1, 0).suggestedOrder, 1);
  assert.equal(replenishmentPreview(84, 100, 3, 7).suggestedOrder, 0);
  assert.deepEqual(replenishmentPreview(0, 12, 3, 7), { dailyDemand: 0, daysCover: null, targetStock: 0, suggestedOrder: 0 });
  assert.equal(replenishmentPreview(84, 0, 0, 0).suggestedOrder, 0);
  assert.equal(replenishmentPreview(0, 0, 3, 7, 10).suggestedOrder, 10);
  assert.equal(replenishmentPreview(84, 5, 3, 7).daysCover, 1);
});
