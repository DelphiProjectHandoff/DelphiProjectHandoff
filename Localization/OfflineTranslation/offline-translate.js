import { BatchTranslator, TranslatorBacking } from './package/translator.js';

const modelFiles = {
  model: './model/model.ende.intgemm.alphas.bin',
  shortlist: './model/lex.50.50.ende.s2t.bin',
  vocab: './model/vocab.deen.spm'
};

class BundledGermanModel extends TranslatorBacking {
  async loadModelRegistery() {
    return [{ from: 'en', to: 'de', files: {} }];
  }

  async loadTranslationModel() {
    const load = async path => {
      const response = await fetch(new URL(path, import.meta.url), { credentials: 'omit' });
      if (!response.ok) throw new Error(`Local model unavailable: ${response.status}`);
      return response.arrayBuffer();
    };
    const [model, shortlist, vocab] = await Promise.all([
      load(modelFiles.model), load(modelFiles.shortlist), load(modelFiles.vocab)
    ]);
    return { model, shortlist, vocabs: [vocab], config: {} };
  }
}

const status = document.getElementById('offline-translation-status');
const passages = [...document.querySelectorAll('pre.project-prose')]
  .filter(element => element.textContent.trim() !== '');
let translator;

try {
  const uncached = [];
  for (const element of passages) {
    const source = element.textContent;
    const bytes = new TextEncoder().encode(source);
    const digest = await crypto.subtle.digest('SHA-256', bytes);
    const key = 'dph-en-de-v1:' + [...new Uint8Array(digest)]
      .map(byte => byte.toString(16).padStart(2, '0')).join('');
    let cached = null;
    try { cached = sessionStorage.getItem(key); } catch { /* Private storage may be disabled. */ }
    if (cached !== null) {
      element.textContent = cached;
      element.lang = 'de';
      element.dir = 'ltr';
    } else {
      uncached.push({ element, source, key });
    }
  }

  if (uncached.length) {
    translator = new BatchTranslator(
      { pivotLanguage: null, workers: 1, batchSize: 4 },
      new BundledGermanModel({ pivotLanguage: null })
    );
    for (const passage of uncached) {
      const result = await translator.translate({
        from: 'en', to: 'de', text: passage.source, html: false
      });
      const translated = result.target.text.trim();
      if (!translated) throw new Error('The local translator returned no text');
      passage.element.textContent = translated;
      passage.element.lang = 'de';
      passage.element.dir = 'ltr';
      try { sessionStorage.setItem(passage.key, translated); } catch { /* Keep the visible result. */ }
    }
  }
  if (status) status.remove();
} catch (error) {
  if (status) status.textContent =
    'Lokale Übersetzung nicht verfügbar. Der ursprüngliche Projekttext wird angezeigt.';
  console.error('DPH offline translation:', error);
} finally {
  document.documentElement.classList.remove('offline-translation-pending');
  if (translator) await translator.delete();
}
