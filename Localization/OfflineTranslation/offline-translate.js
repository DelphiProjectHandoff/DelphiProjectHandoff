import { BatchTranslator, TranslatorBacking } from './package/translator.js';

const targetLanguage = document.documentElement.lang.split('-')[0].toLowerCase();
const models = {
  bg: {
    model: './model/enbg/model.enbg.intgemm.alphas.bin',
    shortlist: './model/enbg/lex.50.50.enbg.s2t.bin',
    vocabs: ['./model/enbg/vocab.enbg.spm']
  },
  cs: {
    model: './model/encs/model.encs.intgemm.alphas.bin',
    shortlist: './model/encs/lex.50.50.encs.s2t.bin',
    vocabs: ['./model/encs/vocab.csen.spm']
  },
  de: {
    model: './model/model.ende.intgemm.alphas.bin',
    shortlist: './model/lex.50.50.ende.s2t.bin',
    vocabs: ['./model/vocab.deen.spm']
  },
  es: {
    model: './model/enes/model.enes.intgemm.alphas.bin',
    shortlist: './model/enes/lex.50.50.enes.s2t.bin',
    vocabs: ['./model/enes/vocab.esen.spm']
  },
  fr: {
    model: './model/enfr/model.intgemm.alphas.bin',
    shortlist: './model/enfr/lex.s2t.bin',
    vocabs: ['./model/enfr/vocab.fren.spm']
  },
  it: {
    model: './model/enit/model.enit.intgemm.alphas.bin',
    shortlist: './model/enit/lex.50.50.enit.s2t.bin',
    vocabs: ['./model/enit/vocab.enit.spm']
  },
  pt: {
    model: './model/enpt/model.enpt.intgemm.alphas.bin',
    shortlist: './model/enpt/lex.50.50.enpt.s2t.bin',
    vocabs: ['./model/enpt/vocab.enpt.spm']
  },
  ru: {
    model: './model/enru/model.enru.intgemm.alphas.bin',
    shortlist: './model/enru/lex.50.50.enru.s2t.bin',
    vocabs: ['./model/enru/vocab.enru.spm']
  },
  uk: {
    model: './model/enuk/model.intgemm8.bin',
    shortlist: './model/enuk/lex.s2t.bin',
    vocabs: ['./model/enuk/vocab.src.spm', './model/enuk/vocab.trg.spm'],
    config: {'gemm-precision': 'int8shiftAll'}
  }
};
const modelFiles = models[targetLanguage];
const messages = {
  bg: {start: 'Текстът на проекта се превежда локално…', failure: 'Някои части не можаха да бъдат преведени и остават на оригиналния език.'},
  cs: {start: 'Text projektu se překládá místně…', failure: 'Některé části se nepodařilo přeložit a zůstávají v původním jazyce.'},
  de: {
    start: 'Der Projekttext wird lokal ins Deutsche übersetzt…',
    failure: 'Einige Abschnitte konnten lokal nicht übersetzt werden. Sie bleiben in der Originalsprache.'
  },
  es: {
    start: 'El texto del proyecto se está traduciendo al español en este equipo…',
    failure: 'No se pudieron traducir algunas secciones. Permanecen en el idioma original.'
  },
  fr: {start: 'Traduction locale du texte du projet…', failure: 'Certains passages n’ont pas pu être traduits et restent dans leur langue d’origine.'},
  it: {start: 'Traduzione locale del testo del progetto…', failure: 'Alcuni passaggi non sono stati tradotti e restano nella lingua originale.'},
  pt: {start: 'Traduzindo o texto do projeto neste computador…', failure: 'Algumas seções não puderam ser traduzidas e permanecem no idioma original.'},
  ru: {start: 'Текст проекта переводится на этом компьютере…', failure: 'Некоторые фрагменты не удалось перевести; они остаются на исходном языке.'},
  uk: {start: 'Текст проєкту перекладається на цьому комп’ютері…', failure: 'Деякі фрагменти не вдалося перекласти; вони залишаються мовою оригіналу.'}
};

class BundledProjectModel extends TranslatorBacking {
  async loadModelRegistery() {
    return [{ from: 'en', to: targetLanguage, files: {} }];
  }

  async loadTranslationModel() {
    const load = async path => {
      const response = await fetch(new URL(path, import.meta.url), { credentials: 'omit' });
      if (!response.ok) throw new Error(`Local model unavailable: ${response.status}`);
      return response.arrayBuffer();
    };
    const [model, shortlist, ...vocabs] = await Promise.all([
      load(modelFiles.model), load(modelFiles.shortlist),
      ...modelFiles.vocabs.map(load)
    ]);
    return { model, shortlist, vocabs, config: modelFiles.config || {} };
  }
}

const status = document.getElementById('offline-translation-status');
if (status) {
  status.lang = targetLanguage;
  status.textContent = messages[targetLanguage].start;
}
const passages = [];
for (const element of document.querySelectorAll('pre.project-prose')) {
  if (element.innerText.trim()) passages.push({
    source: element.innerText,
    apply: translated => {
      element.textContent = translated;
      element.lang = targetLanguage;
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
    const key = `dph-en-${targetLanguage}-v1:` + [...new Uint8Array(digest)]
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
      new BundledProjectModel({ pivotLanguage: null })
    );
    let completed = 0;
    let failures = 0;
    for (let index = 0; index < uncached.length; index += 24) {
      const batch = uncached.slice(index, index + 24);
      const results = await Promise.allSettled(batch.map(async passage => {
        const result = await translator.translate({
          from: 'en', to: targetLanguage, text: passage.source, html: false
        });
        const translated = result.target.text.trim();
        if (!translated) throw new Error('The local translator returned no text');
        passage.apply(translated);
        try { sessionStorage.setItem(passage.key, translated); } catch { /* Keep the visible result. */ }
      }));
      failures += results.filter(result => result.status === 'rejected').length;
      completed += batch.length;
      if (status) status.textContent = `${messages[targetLanguage].start} ${completed}/${uncached.length}`;
      if (results.every(result => result.status === 'rejected'))
        throw new Error('The local translator could not translate this batch');
    }
    if (failures) throw new Error(`${failures} passages could not be translated`);
  }
  if (status) status.remove();
} catch (error) {
  if (status) status.textContent = messages[targetLanguage].failure;
  console.error('DPH offline translation:', error);
} finally {
  document.documentElement.classList.remove('offline-translation-pending');
  if (translator) await translator.delete();
}
