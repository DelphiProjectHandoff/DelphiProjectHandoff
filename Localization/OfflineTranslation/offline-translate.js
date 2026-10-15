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
const passages = [];
for (const element of document.querySelectorAll('pre.project-prose')) {
  if (element.innerText.trim()) passages.push({
    source: element.innerText,
    apply: translated => {
      element.textContent = translated;
      element.lang = 'de';
      element.dir = 'ltr';
    }
  });
}
for (const article of document.querySelectorAll('article.project-prose')) {
  const walker = document.createTreeWalker(article, NodeFilter.SHOW_TEXT);
  while (walker.nextNode()) {
    const node = walker.currentNode;
    const parent = node.parentElement;
    if (!parent.closest('p,h2,h3,li,td,th,blockquote') ||
        parent.closest('code,pre,a,script,style,h1')) continue;
    const fullText = node.textContent;
    const source = fullText.trim();
    if (source.length < 3 || !/[A-Za-z]/.test(source) ||
        /^(?:https?:\/\/|[A-Za-z]:[\\/])/.test(source) ||
        /\.(?:pas|dfm|fmx|dpr|dproj|exe|dll)$/i.test(source)) continue;
    const start = fullText.indexOf(source);
    const prefix = fullText.slice(0, start);
    const suffix = fullText.slice(start + source.length);
    passages.push({
      source,
      apply: translated => { node.textContent = prefix + translated + suffix; }
    });
  }
}
let translator;

try {
  const uncached = [];
  for (const passage of passages) {
    const bytes = new TextEncoder().encode(passage.source);
    const digest = await crypto.subtle.digest('SHA-256', bytes);
    const key = 'dph-en-de-v1:' + [...new Uint8Array(digest)]
      .map(byte => byte.toString(16).padStart(2, '0')).join('');
    let cached = null;
    try { cached = sessionStorage.getItem(key); } catch { /* Private storage may be disabled. */ }
    if (cached !== null) {
      passage.apply(cached);
    } else {
      uncached.push({ ...passage, key });
    }
  }

  if (uncached.length) {
    translator = new BatchTranslator(
      { pivotLanguage: null, workers: 1, batchSize: 8 },
      new BundledGermanModel({ pivotLanguage: null })
    );
    let completed = 0;
    let failures = 0;
    for (let index = 0; index < uncached.length; index += 24) {
      const batch = uncached.slice(index, index + 24);
      const results = await Promise.allSettled(batch.map(async passage => {
        const result = await translator.translate({
          from: 'en', to: 'de', text: passage.source, html: false
        });
        const translated = result.target.text.trim();
        if (!translated) throw new Error('The local translator returned no text');
        passage.apply(translated);
        try { sessionStorage.setItem(passage.key, translated); } catch { /* Keep the visible result. */ }
      }));
      failures += results.filter(result => result.status === 'rejected').length;
      completed += batch.length;
      if (status) status.textContent = `Projekttext lokal übersetzt: ${completed} von ${uncached.length} Abschnitten.`;
      if (results.every(result => result.status === 'rejected'))
        throw new Error('The local translator could not translate this batch');
    }
    if (failures) throw new Error(`${failures} passages could not be translated`);
  }
  if (status) status.remove();
} catch (error) {
  if (status) status.textContent =
    'Einige Abschnitte konnten lokal nicht übersetzt werden. Sie bleiben in der Originalsprache.';
  console.error('DPH offline translation:', error);
} finally {
  document.documentElement.classList.remove('offline-translation-pending');
  if (translator) await translator.delete();
}
