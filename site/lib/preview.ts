// Presentation-only examples. No exchange rates, saved settings or POS writes.
export const previewCurrencies = ["BDT", "USD", "EUR", "GBP", "AED", "SAR", "INR", "CAD", "AUD", "SGD", "MYR", "PKR"] as const;

export function formatPreviewMoney(minor: number, currency: string, locale: string) {
  // Match the POS's fixed 100 minor units even if an ICU currency default differs.
  return new Intl.NumberFormat(locale, { style: "currency", currency, currencyDisplay: "code", minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(minor / 100);
}

export function inclusiveTaxMinor(grossMinor: number, basisPoints: number) {
  return Math.floor((grossMinor * basisPoints + (10000 + basisPoints) / 2) / (10000 + basisPoints));
}

export function replenishmentPreview(soldIn28Days: number, onHand: number, leadDays: number, coverDays: number, minimumStock = 0) {
  const dailyDemand = soldIn28Days / 28;
  const targetStock = Math.max(minimumStock, Math.ceil(soldIn28Days * (leadDays + coverDays) / 28));
  return {
    dailyDemand,
    daysCover: dailyDemand > 0 ? Math.floor(onHand * 28 / soldIn28Days) : null,
    targetStock,
    suggestedOrder: Math.max(0, targetStock - onHand),
  };
}
