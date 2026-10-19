"use client";

import { AnimatePresence, MotionConfig, motion, useReducedMotion } from "framer-motion";
import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import { copy, type Locale } from "./copy";
import ReadinessPreview from "./readiness-preview";

const WA = "https://wa.me/8801842168117";
const EMAIL = "mailto:fabrything@gmail.com";

function Arrow({ diagonal = false }: { diagonal?: boolean }) {
  return <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" className="arrow"><path d={diagonal ? "M6 18 18 6M6 6h12v12" : "M4 12h15m-6-6 6 6-6 6"} stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" /></svg>;
}

function Mark() {
  return <svg className="brand-mark" aria-hidden="true" viewBox="0 0 40 40" fill="none"><rect width="40" height="40" rx="12" fill="currentColor" /><path d="M11 13h6.5a5 5 0 0 1 0 10H11V13Zm0 10h10a4 4 0 0 1 0 8H11V13m16-4v11" stroke="#080e0c" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" /><path d="M23 14h8" stroke="#080e0c" strokeWidth="3" strokeLinecap="round" /></svg>;
}

function Icon({ kind }: { kind: "wallet" | "stock" | "money" | "offline" | "check" }) {
  const paths = {
    wallet: <><path d="M4 7h15v14H4zM4 7V4h13v3" /><path d="M14 12h7v5h-7z" /></>,
    stock: <><path d="m12 3 9 5-9 5-9-5 9-5ZM3 8v9l9 5 9-5V8M12 13v9M7 5l9 5" /></>,
    money: <><rect x="3" y="5" width="18" height="14" rx="2" /><circle cx="12" cy="12" r="3" /><path d="M6 12h.01M18 12h.01" /></>,
    offline: <><path d="M4 9a13 13 0 0 1 16 0M7 13a8 8 0 0 1 10 0M10 17a3 3 0 0 1 4 0" /><circle cx="12" cy="20" r=".5" /><path d="m3 3 18 18" /></>,
    check: <path d="m5 12 4 4L19 6" />,
  };
  return <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round">{paths[kind]}</svg>;
}

function Reveal({ children, className = "", delay = 0 }: { children: ReactNode; className?: string; delay?: number }) {
  const reduced = useReducedMotion();
  return <motion.div className={className} initial={reduced ? false : { opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, margin: "-40px" }} transition={{ duration: 0.65, delay, ease: [0.22, 1, 0.36, 1] }}>{children}</motion.div>;
}

function Eyebrow({ children }: { children: ReactNode }) { return <p className="eyebrow">{children}</p>; }

export default function Showcase() {
  const [locale, setLocale] = useState<Locale>("en");
  const [tab, setTab] = useState(0);
  const [videoOpen, setVideoOpen] = useState(false);
  const [enquiry, setEnquiry] = useState({ name: "", contact: "", message: "" });
  const reduced = useReducedMotion();
  const dialogRef = useRef<HTMLDialogElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const tabRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const t = copy[locale];
  const enquiryBody = [enquiry.message.trim(), enquiry.name.trim() ? `${t.contactFormName}: ${enquiry.name.trim()}` : "", enquiry.contact.trim() ? `${t.contactFormContact}: ${enquiry.contact.trim()}` : ""].filter(Boolean).join("\n\n");
  const canSend = enquiry.message.trim().length > 0;
  const waHref = `${WA}?text=${encodeURIComponent(enquiryBody)}`;
  const mailHref = `${EMAIL}?subject=${encodeURIComponent(t.contactFormSubject)}&body=${encodeURIComponent(enquiryBody)}`;
  const tabId = useId();
  const brand = locale === "bn" ? "বেচাকেনা" : "BechaKena";
  const imagePaths = [locale === "bn" ? "/media/pos-bn.png" : "/media/pos-en.png", "/media/restaurant.png", "/media/reports.png", "/media/receipt.png"];
  const stockTokens = locale === "bn" ? ["+৫,০০০", "−১,০০০", "+১,০০০"] : ["+5,000", "−1,000", "+1,000"];
  const stockTotal = locale === "bn" ? "৫,০০০" : "5,000";

  useEffect(() => {
    try {
      const saved = localStorage.getItem("bechakena.site.locale");
      if (saved === "en" || saved === "bn") setLocale(saved);
    } catch { /* Storage is optional for the presentation. */ }
  }, []);

  useEffect(() => { document.documentElement.lang = locale; }, [locale]);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (videoOpen) {
      dialog.showModal();
      document.body.style.overflow = "hidden";
    } else {
      dialog.close();
      videoRef.current?.pause();
      document.body.style.overflow = "";
    }
    return () => { document.body.style.overflow = ""; };
  }, [videoOpen]);

  function changeLocale(next: Locale) {
    setLocale(next);
    try { localStorage.setItem("bechakena.site.locale", next); } catch { /* No storage requirement. */ }
  }

  return <MotionConfig reducedMotion="user"><div className={`site locale-${locale}`}>
    <a className="skip-link" href="#main">{t.skip}</a>
    <header className="header" id="top"><div className="container nav">
      <a className="brand" href="#top" aria-label={brand}><Mark /><span>{brand}<small>neWell Software</small></span></a>
      <nav className="nav-links" aria-label={t.menu}><a href="#product">{t.product}</a><a href="#modules">{t.modules}</a><a href="#ownership">{t.pricing}</a></nav>
      <div className="nav-actions"><div className="language-switch" role="group" aria-label={t.languageLabel}><button lang="en" aria-pressed={locale === "en"} onClick={() => changeLocale("en")}>EN</button><button lang="bn" aria-pressed={locale === "bn"} onClick={() => changeLocale("bn")}>বাংলা</button></div><a className="nav-demo" href="/demo/">{t.tryDemo}<Arrow diagonal /></a></div>
    </div></header>

    <main id="main">
      <section className="hero container" aria-labelledby="hero-title">
        <div className="hero-intro"><motion.div initial={false} animate={{ opacity: 1 }}><Eyebrow><span className="status-dot" />{t.eyebrow}</Eyebrow><h1 id="hero-title">{t.heroFirst}<br /><span>{t.heroSecond}</span></h1></motion.div><div className="hero-copy"><p>{t.heroBody}</p><div className="button-row"><a className="button button-primary" href="/demo/">{t.tryDemo}<Arrow diagonal /></a><button className="text-button" onClick={() => setVideoOpen(true)}><span className="play-icon" aria-hidden="true">▷</span>{t.heroSecondary}</button></div><p className="micro hero-note">{t.localNote}</p></div></div>
        <motion.div className="hero-product" initial={reduced ? false : { opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.9, delay: 0.1, ease: [0.22, 1, 0.36, 1] }}>
          <div className="product-glow" aria-hidden="true" /><div className="device-frame"><div className="device-top"><span className="window-dots" aria-hidden="true"><i /><i /><i /></span><span>{brand} / {t.tabs[0].short}</span><span className="device-status"><i />{t.offlineBadge}</span></div><img className="hero-screen" src={imagePaths[0]} alt={t.heroImageAlt} width="1440" height="1000" fetchPriority="high" /></div>
          <div className="floating-note"><span className="note-icon"><Icon kind="offline" /></span><div><strong>{t.offlineBadge}</strong><span>{t.offlineBadgeBody}</span></div><i className="status-dot" /></div>
          <div className="capture-label"><span className="tiny-square" aria-hidden="true" />{t.heroCaption}</div>
        </motion.div>
        <div className="proof-strip">{t.proof.map((item, i) => <span key={i}><Icon kind="check" />{item}</span>)}</div>
      </section>

      <section className="section container product-section" id="product" aria-labelledby="tour-title">
        <Reveal className="section-heading"><div><Eyebrow>{t.tourEyebrow}</Eyebrow><h2 id="tour-title">{t.tourTitle}<br /><span className="muted-heading">{t.tourAccent}</span></h2></div><p className="section-lede">{t.tourBody}</p></Reveal>
        <Reveal><div className="tour-tabs" role="tablist" aria-label={t.product}>{t.tabs.map((item, i) => <button key={i} ref={el => { tabRefs.current[i] = el; }} type="button" role="tab" aria-selected={tab === i} aria-controls={`${tabId}-panel-${i}`} id={`${tabId}-tab-${i}`} tabIndex={tab === i ? 0 : -1} onClick={() => setTab(i)} onKeyDown={event => {
          let next = tab;
          if (event.key === "ArrowRight") next = (tab + 1) % 4;
          else if (event.key === "ArrowLeft") next = (tab + 3) % 4;
          else if (event.key === "Home") next = 0;
          else if (event.key === "End") next = 3;
          else return;
          event.preventDefault(); setTab(next); tabRefs.current[next]?.focus();
        }}><span className="tab-number">0{i + 1}</span>{item.short}<span className="tab-indicator" aria-hidden="true" /></button>)}</div></Reveal>
        <div className="tour-panels">{t.tabs.map((item, i) => <div key={i} role="tabpanel" hidden={tab !== i} id={`${tabId}-panel-${i}`} aria-labelledby={`${tabId}-tab-${i}`} tabIndex={0}><div className="tour-panel"><AnimatePresence mode="wait"><motion.div key={`${i}-${locale}`} className="tour-description" initial={reduced ? false : { opacity: 0, x: -12 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }}><span className="large-index" aria-hidden="true">0{i + 1}</span><h3>{item.title}</h3><p>{item.description}</p><p className="micro detail-note">{item.detail}</p><a className="inline-link" href="/demo/">{t.tryDemo}<Arrow /></a></motion.div></AnimatePresence><div className={`tour-image-wrap ${i === 3 ? "receipt-image" : ""}`}><img src={imagePaths[i]} alt={item.alt} width="1440" height="1000" loading="lazy" /></div></div></div>)}</div>
        <p className="micro capture-footnote">{t.captureNote}</p>
      </section>

      <section className="section foundations container" aria-labelledby="foundations-title"><Reveal><Eyebrow>{t.foundationsEyebrow}</Eyebrow><h2 id="foundations-title">{t.foundationTitle}<br /><span className="muted-heading">{t.foundationAccent}</span></h2></Reveal><div className="foundation-grid">{t.foundations.map((item, i) => <Reveal className="foundation" key={i} delay={i * 0.08}><div className="feature-icon"><Icon kind={(["wallet", "stock", "money"] as const)[i]} /></div><span className="eyebrow small-eyebrow">{item.label}</span><h3>{item.title}</h3><p>{item.text}</p></Reveal>)}</div></section>

      <section className="section quality-section container" aria-labelledby="quality-title">
        <Reveal className="quality-head"><div><Eyebrow>{t.qualityEyebrow}</Eyebrow><h2 id="quality-title">{t.qualityTitle}<br /><span className="muted-heading">{t.qualityAccent}</span></h2></div><p className="section-lede">{t.qualityBody}</p></Reveal>
        <div className="quality-grid">
          <Reveal className="quality-card">
            <div className="qviz qviz-fast" aria-hidden="true">
              <p className="qviz-cloud"><Icon kind="offline" />{t.qualityVizCloud}<i className="cloud-strike" /></p>
              <div className="qviz-rows"><span /><span /><span className="qviz-gone"><i>{t.qualityVizFiltered}</i></span><span /></div>
              <i className="qviz-beam" />
              <b className="qviz-chip">{t.qualityVizLocal}</b>
            </div>
            <span className="quality-tag">{t.qualityCards[0].tag}</span><h3>{t.qualityCards[0].title}</h3><p>{t.qualityCards[0].text}</p><p className="micro quality-caption">{t.qualityCards[0].caption}</p>
          </Reveal>
          <Reveal className="quality-card" delay={0.08}>
            <div className="qviz qviz-sum" aria-hidden="true">
              <div className="qviz-tokens">{stockTokens.map((token, i) => <span key={token} className={`qviz-token token-${i}`}>{token}</span>)}</div>
              <div className="qviz-sum-box"><span>Σ</span><strong>{stockTotal}</strong><em>{t.qualityVizStock}</em></div>
            </div>
            <span className="quality-tag">{t.qualityCards[1].tag}</span><h3>{t.qualityCards[1].title}</h3><p>{t.qualityCards[1].text}</p><p className="micro quality-caption">{t.qualityCards[1].caption}</p>
          </Reveal>
          <Reveal className="quality-card" delay={0.16}>
            <div className="qviz qviz-checks" aria-hidden="true">
              <div className="qviz-term">{t.qualityVizChecks.map((line, i) => <span key={line} className={`qterm-line qterm-${i}`}><Icon kind="check" />{line}</span>)}</div>
              <div className="qterm-bar"><i /><b>{t.qualityVizAll}</b></div>
            </div>
            <span className="quality-tag">{t.qualityCards[2].tag}</span><h3>{t.qualityCards[2].title}</h3><p>{t.qualityCards[2].text}</p><p className="micro quality-caption">{t.qualityCards[2].caption}</p>
          </Reveal>
        </div>
        <Reveal className="quality-gates">{t.qualityGates.map(gate => <span key={gate}><Icon kind="check" />{gate}</span>)}</Reveal>
      </section>

      <section className="offline-section" aria-labelledby="offline-title"><div className="container offline-layout"><Reveal><Eyebrow><span className="status-dot" />{t.offlineEyebrow}</Eyebrow><h2 id="offline-title">{t.offlineTitle}<br /><span>{t.offlineAccent}</span></h2><p className="offline-body">{t.offlineBody}</p></Reveal><Reveal className="offline-diagram"><div className="offline-orbit" aria-hidden="true"><div className="orbit orbit-one" /><div className="orbit orbit-two" /><div className="orbit orbit-three" /><div className="orbit-center"><Mark /></div><span className="orbit-node node-one"><Icon kind="stock" /></span><span className="orbit-node node-two"><Icon kind="wallet" /></span><span className="orbit-node node-three"><Icon kind="money" /></span></div><ol className="offline-steps">{t.offlineFlow.map((step, i) => <li key={i}><Icon kind="check" /><span>{step}</span></li>)}</ol></Reveal><p className="micro offline-foot">{t.offlineFoot}</p></div></section>

      <section className="section container" id="modules" aria-labelledby="modules-title"><Reveal className="section-heading"><div><Eyebrow>{t.moduleEyebrow}</Eyebrow><h2 id="modules-title">{t.moduleTitle}<br /><span className="muted-heading">{t.moduleAccent}</span></h2></div><p className="section-lede">{t.moduleBody}</p></Reveal><div className="module-grid"><Reveal className="module-card retail-card"><div className="module-copy"><Eyebrow>{t.retailTag}</Eyebrow><h3>{t.retailTitle}</h3><p>{t.retailText}</p><a className="inline-link" href="/demo/">{t.moduleLink}<Arrow diagonal /></a></div><div className="module-image"><img src={imagePaths[0]} alt={t.tabs[0].alt} width="1440" height="1000" loading="lazy" /></div></Reveal><Reveal className="module-card restaurant-card" delay={0.1}><div className="module-copy"><Eyebrow>{t.restaurantTag}</Eyebrow><h3>{t.restaurantTitle}</h3><p>{t.restaurantText}</p><a className="inline-link" href="/demo/">{t.moduleLink}<Arrow diagonal /></a></div><div className="module-image"><img src="/media/restaurant.png" alt={t.tabs[1].alt} width="1440" height="1000" loading="lazy" /></div></Reveal></div></section>

      <section className="section how-section container" aria-labelledby="how-title"><Reveal><Eyebrow>{t.howEyebrow}</Eyebrow><h2 id="how-title">{t.howTitle}</h2></Reveal><div className="how-grid">{t.howSteps.map((item, i) => <Reveal key={i} delay={i * 0.08}><span className="step-number">0{i + 1}</span><h3>{item.title}</h3><p>{item.text}</p></Reveal>)}</div></section>

      <section className="global-section" id="global" aria-labelledby="global-title"><div className="container"><Reveal className="section-heading readiness-heading"><div><Eyebrow>{t.globalEyebrow}</Eyebrow><h2 id="global-title">{t.globalTitle}<br /><span className="muted-heading">{t.globalAccent}</span></h2></div><p className="section-lede">{t.globalBody}</p></Reveal><ReadinessPreview locale={locale} /></div></section>

      <section className="section container" id="ownership" aria-labelledby="ownership-title"><Reveal className="ownership-heading"><Eyebrow>{t.ownershipEyebrow}</Eyebrow><h2 id="ownership-title">{t.ownershipTitle}<br /><span className="muted-heading">{t.ownershipAccent}</span></h2><p>{t.ownershipBody}</p></Reveal><div className="plan-grid"><Reveal className="plan local-plan"><div className="plan-tag"><span className="status-dot" />{t.localPlanTag}</div><h3>{t.localPlan}</h3><p>{t.localPlanBody}</p><ul>{t.localPlanFeatures.map(feature => <li key={feature}><Icon kind="check" />{feature}</li>)}</ul><a className="button button-primary" href={WA} target="_blank" rel="noopener noreferrer">{t.localPlanCta}<Arrow diagonal /></a><p className="micro">{t.noPrice}</p></Reveal><Reveal className="plan cloud-plan" delay={0.08}><div className="plan-tag">{t.cloudTag}</div><h3>{t.cloudPlan}</h3><p>{t.cloudPlanBody}</p><ul>{t.cloudPlanFeatures.map(feature => <li key={feature}><span className="planned-dot" />{feature}</li>)}</ul><a className="button button-outline" href={EMAIL}>{t.cloudCta}<Arrow /></a><p className="micro">{t.cloudFoot}</p></Reveal></div></section>

      <section className="section faq-section container" aria-labelledby="faq-title"><Reveal><Eyebrow>{t.faqEyebrow}</Eyebrow><h2 id="faq-title">{t.faqTitle}</h2></Reveal><div className="faq-list">{t.faqs.map((faq, i) => <details key={i}><summary>{faq.q}<span className="faq-plus" aria-hidden="true">+</span></summary><p>{faq.a}</p></details>)}</div></section>

      <section className="contact-section" id="contact" aria-labelledby="contact-title"><div className="contact-glow" aria-hidden="true" /><Reveal className="container contact-content"><Eyebrow>{t.contactEyebrow}</Eyebrow><h2 id="contact-title">{t.contactTitle}<br /><span>{t.contactAccent}</span></h2><p>{t.contactBody}</p><div className="button-row"><a className="button button-primary" href={WA} target="_blank" rel="noopener noreferrer">{t.whatsapp}<Arrow diagonal /></a><a className="button button-outline" href={EMAIL}>{t.email}<Arrow /></a></div><form className="contact-form" onSubmit={event => event.preventDefault()}><h3>{t.contactFormTitle}</h3><label>{t.contactFormName}<input name="name" type="text" autoComplete="name" value={enquiry.name} onChange={event => setEnquiry(previous => ({ ...previous, name: event.target.value }))} /></label><label>{t.contactFormContact}<input name="contact" type="text" autoComplete="email" value={enquiry.contact} onChange={event => setEnquiry(previous => ({ ...previous, contact: event.target.value }))} /></label><label>{t.contactFormMessage}<textarea name="message" required placeholder={t.contactFormPlaceholder} value={enquiry.message} onChange={event => setEnquiry(previous => ({ ...previous, message: event.target.value }))} /></label><div className="contact-form-actions"><button className="button button-primary" type="button" disabled={!canSend} onClick={() => window.open(waHref, "_blank", "noopener,noreferrer")}>{t.contactFormWhatsapp}<Arrow diagonal /></button><button className="button button-outline" type="button" disabled={!canSend} onClick={() => { window.location.href = mailHref; }}>{t.contactFormEmail}<Arrow /></button></div><p className="micro">{t.contactFormNote}</p></form><p className="micro">{t.contactNote}</p></Reveal></section>
    </main>

    <footer className="container footer"><div className="footer-main"><a className="brand" href="#top"><Mark /><span>{brand}<small>neWell Software</small></span></a><p>{t.footerLine}</p><a className="inline-link" href="#top">{t.backTop}<span className="back-arrow"><Arrow /></span></a></div><div className="footer-bottom"><span>{t.rights}</span><span>{t.company}</span><a href="/demo/">{t.demoNote}</a></div></footer>

    <dialog ref={dialogRef} className="video-dialog" aria-label={t.playVideo} onCancel={() => setVideoOpen(false)} onClick={event => { if (event.target === event.currentTarget) setVideoOpen(false); }}><div className="video-dialog-top"><p>{t.videoCaption}</p><button type="button" onClick={() => setVideoOpen(false)} aria-label={t.close}>{t.close}<span aria-hidden="true">×</span></button></div>{videoOpen && <video ref={videoRef} controls playsInline preload="metadata" poster={imagePaths[0]} aria-label={t.playVideo}><source src="/media/showcase.webm" type="video/webm" /></video>}<p className="micro">{t.demoNote}</p></dialog>
  </div></MotionConfig>;
}
