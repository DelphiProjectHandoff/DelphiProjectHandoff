(function () {
  'use strict';
  var wrapper = document.querySelector('.gtranslate_wrapper');
  if (!wrapper) return;
  var aliases = { iw: 'he', tl: 'fil' };
  var names = { 'zh-CN': 'Chinese, Simplified', 'zh-TW': 'Chinese, Traditional' };
  var displayNames = typeof Intl.DisplayNames === 'function' ?
    new Intl.DisplayNames(['en'], { type: 'language' }) : null;

  function englishName(code) {
    if (names[code]) return names[code];
    if (!displayNames) return code;
    try { return displayNames.of(aliases[code] || code) || code; }
    catch (error) { return code; }
  }

  function improveMenu() {
    wrapper.querySelectorAll('a[data-gt-lang]').forEach(function (link) {
      if (link.dataset.bilingualLabel === 'true') return;
      var nativeName = link.textContent.trim();
      var name = englishName(link.dataset.gtLang);
      var label = name.toLocaleLowerCase('en') === nativeName.toLocaleLowerCase('en') ?
        name : name + ' (' + nativeName + ')';
      var flag = link.querySelector('img');
      link.dataset.bilingualLabel = 'true';
      link.setAttribute('aria-label', label);
      link.replaceChildren(flag ? flag.cloneNode(true) : document.createTextNode(''),
        document.createTextNode(label));
    });
    wrapper.querySelectorAll('.gt_options').forEach(function (list) {
      var current = Array.prototype.slice.call(list.children).filter(function (item) {
        return item.matches('a[data-gt-lang]');
      });
      var sorted = current.slice().sort(function (a, b) {
        return a.textContent.trim().localeCompare(b.textContent.trim(), 'en');
      });
      if (sorted.some(function (item, index) { return item !== current[index]; })) {
        sorted.forEach(function (item) { list.appendChild(item); });
      }
    });
  }
  new MutationObserver(improveMenu).observe(wrapper, { childList: true, subtree: true });
  improveMenu();
}());
