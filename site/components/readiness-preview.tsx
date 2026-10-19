"use client";

import { motion, useReducedMotion } from "framer-motion";
import { useId, useState } from "react";
import { formatPreviewMoney, inclusiveTaxMinor, previewCurrencies, replenishmentPreview } from "../lib/preview";
import type { Locale } from "./copy";

const labels = {
  en: {
    preview: "INTERACTIVE SAMPLE · DOES NOT CHANGE THE POS", receipt: "Make the receipt feel like home.",
    business: "Sample business name", currency: "Currency · 2 decimal places", taxLabel: "Tax label", taxRate: "Included tax · sample rate",
    language: "Receipt number format", english: "English", bangla: "বাংলা", sample: "SAMPLE RECEIPT", shop: "Your neighborhood shop",
    item: "Everyday essentials", extra: "Counter favorite", total: "Total", included: "included", minor: "Stored as integer minor units",
    note: "Sample prices are tax inclusive. Changing currency relabels this sample only; it does not exchange money. The POS protects existing financial history from currency relabeling. Local tax and receipt requirements still need review.",
    stockEyebrow: "FROM SALES HISTORY TO A BUYING DECISION", stockTitle: "What should you order next?", stockBody: "Explore a sample of the offline replenishment workflow: recent demand, stock on hand, and your own lead and cover days. The product uses the selected branch’s records and exports suggestions to CSV.",
    stockSample: "SAMPLE SCENARIO · NOT LIVE INVENTORY", sold: "Units sold in the last 28 days", onHand: "Units on hand", lead: "Supplier lead time", cover: "Extra stock coverage", days: "days", units: "units", suggest: "Suggested order", demand: "Average daily demand", coverage: "Stock covers", noDemand: "No recent demand", rule: "Target = round up (28-day sales ÷ 28 × (lead + cover days)). Order = target − on hand, with a minimum of zero.",
    minimum: "Minimum stock", stockNote: "This whole-unit sample also respects your minimum stock. Without recent sales, the minimum can still trigger an order. Review seasonality, returns and supplier minimums before buying. This is a transparent buying aid, not an AI forecast or a purchase order.", try: "Explore the actual POS", setup: "Setup still needs local review", setupBody: "English and Bengali are the available interface languages. A currency setting does not add payment processing, fiscal certification or country-specific compliance.",
  },
  bn: {
    preview: "ইন্টারঅ্যাকটিভ নমুনা · POS-এর সেটিং বদলায় না", receipt: "রসিদে থাকুক আপনার দোকানের পরিচয়।",
    business: "নমুনা দোকানের নাম", currency: "মুদ্রা · দশমিকের পর ২ ঘর", taxLabel: "করের নাম", taxRate: "অন্তর্ভুক্ত কর · নমুনা হার",
    language: "রসিদের সংখ্যার ধরন", english: "English", bangla: "বাংলা", sample: "নমুনা রসিদ", shop: "আপনার পাড়ার দোকান",
    item: "নিত্যপ্রয়োজনীয় পণ্য", extra: "পছন্দের পণ্য", total: "মোট", included: "অন্তর্ভুক্ত", minor: "পূর্ণ ক্ষুদ্র এককে টাকার হিসাব",
    note: "নমুনা দামে কর অন্তর্ভুক্ত। মুদ্রা বাছলে শুধু নমুনার মুদ্রা বদলায়; বিনিময় হার প্রয়োগ হয় না। POS আগের আর্থিক ইতিহাসের মুদ্রা বদলানো থেকে সুরক্ষা দেয়। স্থানীয় কর ও রসিদের শর্ত যাচাই করতে হবে।",
    stockEyebrow: "বিক্রির ইতিহাস থেকে কেনার সিদ্ধান্ত", stockTitle: "এবার কতটা কিনবেন?", stockBody: "অফলাইন মজুত পরিকল্পনার নমুনা দেখুন: সাম্প্রতিক বিক্রি, হাতে থাকা মজুত এবং আপনার ঠিক করা সরবরাহ ও বাড়তি মজুতের দিন। আসল অ্যাপ নির্বাচিত শাখার রেকর্ড ব্যবহার করে এবং পরামর্শ CSV-তে রপ্তানি করে।",
    stockSample: "নমুনা পরিস্থিতি · আসল মজুত নয়", sold: "গত ২৮ দিনে বিক্রি হওয়া ইউনিট", onHand: "হাতে থাকা ইউনিট", lead: "সরবরাহ পেতে সময়", cover: "বাড়তি মজুতের দিন", days: "দিন", units: "ইউনিট", suggest: "কেনার পরামর্শ", demand: "দৈনিক গড় বিক্রি", coverage: "মজুত চলবে", noDemand: "সাম্প্রতিক বিক্রি নেই", rule: "লক্ষ্য = (২৮ দিনের বিক্রি ÷ ২৮ × (সরবরাহের দিন + বাড়তি মজুতের দিন)), ওপরের পূর্ণ সংখ্যায়। কেনার পরামর্শ = লক্ষ্য − হাতে থাকা মজুত; সর্বনিম্ন শূন্য।",
    minimum: "সর্বনিম্ন মজুত", stockNote: "পূর্ণ ইউনিটের এই নমুনায় সর্বনিম্ন মজুতও ধরা হয়। সাম্প্রতিক বিক্রি না থাকলেও সর্বনিম্ন মজুত পূরণে কেনার পরামর্শ আসতে পারে। কেনার আগে মৌসুমি চাহিদা, ফেরত ও সরবরাহকারীর ন্যূনতম পরিমাণ বিবেচনা করুন। এটি হিসাবের সহায়তা; AI পূর্বাভাস বা ক্রয়াদেশ নয়।", try: "আসল POS দেখুন", setup: "স্থানীয় প্রয়োজন যাচাই করুন", setupBody: "ইন্টারফেসের ভাষা ইংরেজি ও বাংলা। মুদ্রা সেটিং পেমেন্ট প্রসেসিং, সরকারি সার্টিফিকেশন বা দেশভিত্তিক আইন মেনে চলার নিশ্চয়তা দেয় না।",
  },
};

export default function ReadinessPreview({ locale }: { locale: Locale }) {
  const t = labels[locale];
  const id = useId();
  const reduced = useReducedMotion();
  const [currency, setCurrency] = useState("BDT");
  const [business, setBusiness] = useState("");
  const [taxLabel, setTaxLabel] = useState("VAT");
  const [taxRate, setTaxRate] = useState(15);
  const [digits, setDigits] = useState<Locale>("en");
  const [sold, setSold] = useState(84);
  const [stock, setStock] = useState(12);
  const [lead, setLead] = useState(3);
  const [cover, setCover] = useState(7);
  const [minimum, setMinimum] = useState(0);
  const format = (minor: number) => formatPreviewMoney(minor, currency, digits === "bn" ? "bn-BD" : "en-US");
  const number = (value: number, decimals = 0) => new Intl.NumberFormat(locale === "bn" ? "bn-BD" : "en-US", { maximumFractionDigits: decimals }).format(value);
  const plan = replenishmentPreview(sold, stock, lead, cover, minimum);
  const tax = inclusiveTaxMinor(30000, taxRate * 100);

  return <>
    <div className="readiness-workbench">
      <div className="readiness-controls">
        <p className="eyebrow">{t.preview}</p><h3>{t.receipt}</h3>
        <label htmlFor={`${id}-business`}>{t.business}<input id={`${id}-business`} value={business} maxLength={60} placeholder={t.shop} onChange={event => setBusiness(event.target.value)} /></label>
        <label htmlFor={`${id}-currency`}>{t.currency}<select id={`${id}-currency`} value={currency} onChange={event => setCurrency(event.target.value)}>{previewCurrencies.map(code => <option key={code}>{code}</option>)}</select></label>
        <div className="readiness-pair"><label htmlFor={`${id}-tax-label`}>{t.taxLabel}<input id={`${id}-tax-label`} maxLength={24} value={taxLabel} onChange={event => setTaxLabel(event.target.value)} /></label><label htmlFor={`${id}-tax-rate`}>{t.taxRate}<select id={`${id}-tax-rate`} value={taxRate} onChange={event => setTaxRate(Number(event.target.value))}>{[0, 5, 10, 15, 20].map(rate => <option key={rate} value={rate}>{number(rate)}%</option>)}</select></label></div>
        <fieldset className="format-languages"><legend>{t.language}</legend><button type="button" aria-pressed={digits === "en"} onClick={() => setDigits("en")}>{t.english}</button><button type="button" aria-pressed={digits === "bn"} onClick={() => setDigits("bn")}>{t.bangla}</button></fieldset>
      </div>
      <div className="receipt-stage"><div className="sample-receipt" aria-live="polite" aria-atomic="true">
        <span className="receipt-overline">{t.sample}</span><h4>{business.trim() || t.shop}</h4><p>BechaKena · {currency}</p><div className="receipt-rule" />
        <div className="receipt-line"><span>{t.item}<small>2 × {format(12550)}</small></span><span>{format(25100)}</span></div><div className="receipt-line"><span>{t.extra}<small>1 × {format(4900)}</small></span><span>{format(4900)}</span></div>
        <div className="receipt-rule" /><div className="receipt-line receipt-total"><span>{t.total}</span><strong>{format(30000)}</strong></div><div className="receipt-line receipt-tax"><span>{taxLabel.trim() || "—"} {number(taxRate)}% · {t.included}</span><span>{format(tax)}</span></div><p className="receipt-storage">{t.minor}<br /><code>30000 · {currency} / 100</code></p>
      </div><p className="micro">{t.note}</p></div>
    </div>
    <div className="readiness-boundary"><span aria-hidden="true">↗</span><div><h3>{t.setup}</h3><p>{t.setupBody}</p></div></div>
    <div className="stock-workbench" id="replenishment">
      <div className="stock-story"><p className="eyebrow">{t.stockEyebrow}</p><h3>{t.stockTitle}</h3><p>{t.stockBody}</p><a className="inline-link" href="/demo/">{t.try} <span aria-hidden="true">↗</span></a></div>
      <div className="stock-simulator"><p className="eyebrow">{t.stockSample}</p>
        {([{ key: "sold", label: t.sold, value: sold, max: 280, setter: setSold, unit: t.units }, { key: "stock", label: t.onHand, value: stock, max: 100, setter: setStock, unit: t.units }, { key: "lead", label: t.lead, value: lead, max: 30, setter: setLead, unit: t.days }, { key: "cover", label: t.cover, value: cover, max: 30, setter: setCover, unit: t.days }, { key: "minimum", label: t.minimum, value: minimum, max: 50, setter: setMinimum, unit: t.units }]).map(control => <label className="stock-slider" key={control.key} htmlFor={`${id}-${control.key}`}><span>{control.label}<output htmlFor={`${id}-${control.key}`}>{number(control.value)} {control.unit}</output></span><input id={`${id}-${control.key}`} type="range" min={control.key === "cover" ? 1 : 0} max={control.max} value={control.value} aria-valuetext={`${number(control.value)} ${control.unit}`} onChange={event => control.setter(Number(event.target.value))} /></label>)}
        <div className="stock-result" aria-live="polite" aria-atomic="true"><div><span>{t.suggest}</span><motion.strong key={plan.suggestedOrder} initial={reduced ? false : { opacity: 0.5, y: 4 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.15 }}>{number(plan.suggestedOrder)} <small>{t.units}</small></motion.strong></div><dl><div><dt>{t.demand}</dt><dd>{number(plan.dailyDemand, 1)}</dd></div><div><dt>{t.coverage}</dt><dd>{plan.daysCover === null ? t.noDemand : `${number(plan.daysCover, 1)} ${t.days}`}</dd></div></dl></div>
        <details className="stock-rule"><summary>{locale === "bn" ? "হিসাবটি যেভাবে হয়" : "Show the calculation"}</summary><p>{t.rule}</p></details><p className="micro stock-caveat">{t.stockNote}</p>
      </div>
    </div>
  </>;
}
