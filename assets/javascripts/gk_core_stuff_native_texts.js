// gk_core_stuff native_texts.
// The browser writes some texts itself, in the browser's language and not the page's: the message of a field that must
// be filled in or has the wrong form ("Please fill out this field", shown on hover and when the form is sent), and a file
// field's button and "No file chosen". In the page's language instead: a field's own message is set from the page's
// texts (setCustomValidity), kept up to date as the field changes; a file field gets a button and a line with the chosen
// files, and the browser's own field stays there without its button and text (the form, a test and a dropped file
// still reach it).
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('native_texts')) return;

  function message(el) {
    var v = el.validity;
    if (!v || v.valid || v.customError && !el.dataset.gkCoreStuffMsg) return '';
    if (v.valueMissing) return el.type === 'checkbox' ? G.t('nt_check') : el.tagName === 'SELECT' ? G.t('nt_choose') : G.t('nt_required');
    if (v.typeMismatch) return el.type === 'email' ? G.t('nt_email') : el.type === 'url' ? G.t('nt_url') : G.t('nt_format');
    if (v.tooShort) return G.t('nt_short').replace('%{n}', el.minLength);
    if (v.tooLong) return G.t('nt_long').replace('%{n}', el.maxLength);
    if (v.rangeUnderflow) return G.t('nt_min').replace('%{n}', el.min);
    if (v.rangeOverflow) return G.t('nt_max').replace('%{n}', el.max);
    if (v.patternMismatch || v.stepMismatch || v.badInput) return el.title || G.t('nt_format');
    return '';
  }
  // the field's message from the page's texts; one the page itself set (another script's) is left alone
  function check(el) {
    if (el.validity && el.validity.customError && !el.dataset.gkCoreStuffMsg) return;
    el.setCustomValidity('');
    var m = message(el);
    el.dataset.gkCoreStuffMsg = m ? '1' : '';
    if (m) el.setCustomValidity(m);
  }

  function fileField(input) {
    if (input.dataset.gkCoreStuffFile) return;
    input.dataset.gkCoreStuffFile = '1';
    var wrap = G.node('span', 'gk-core-stuff-file');
    var btn = G.node('button', 'gk-core-stuff-file-button', G.t(input.multiple ? 'nt_files_choose' : 'nt_file_choose'));
    btn.type = 'button';
    var name = G.node('span', 'gk-core-stuff-file-name');
    function paint() {
      var n = input.files ? input.files.length : 0;
      name.textContent = n === 0 ? G.t('nt_file_none') : n === 1 ? input.files[0].name : G.t('nt_files_n').replace('%{n}', n);
    }
    input.parentNode.insertBefore(wrap, input);
    wrap.appendChild(input); wrap.appendChild(btn); wrap.appendChild(name);
    input.classList.add('gk-core-stuff-file-native');
    input.tabIndex = -1;
    btn.addEventListener('click', function () { input.click(); });
    input.addEventListener('change', paint);
    // a file dropped on the button or the text goes into the field, as a drop on the browser's own field does
    wrap.addEventListener('dragover', function (e) { e.preventDefault(); wrap.classList.add('gk-core-stuff-file-over'); });
    wrap.addEventListener('dragleave', function () { wrap.classList.remove('gk-core-stuff-file-over'); });
    wrap.addEventListener('drop', function (e) {
      e.preventDefault(); wrap.classList.remove('gk-core-stuff-file-over');
      if (!e.dataTransfer || !e.dataTransfer.files.length) return;
      input.files = e.dataTransfer.files;
      input.dispatchEvent(new Event('change', { bubbles: true }));
    });
    paint();
  }

  var SEL = 'input:not([type=hidden]):not([type=submit]):not([type=button]):not([type=file]), select, textarea';
  G.onContent(function (root) {
    root.querySelectorAll(SEL).forEach(function (el) {
      if (el.dataset.gkCoreStuffNt || !el.willValidate) return;
      el.dataset.gkCoreStuffNt = '1';
      check(el);
      ['input', 'change', 'invalid'].forEach(function (k) { el.addEventListener(k, function () { check(el); }); });
    });
    root.querySelectorAll('input[type=file]').forEach(fileField);
  });
})();
