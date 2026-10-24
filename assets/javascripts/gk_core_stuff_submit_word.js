// gk_core_stuff submit_word: the word on core's submit button ("Skicka") becomes core's own word for save ("Spara"),
// in whatever language the person has: the two words are core's translations, none of ours.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('submit_word')) return;
  var w = G.opt('submit_word');
  if (!w.from || !w.to || w.from === w.to) return;
  G.onContent(function (root) {
    root.querySelectorAll('input[type="submit"]:not([data-gk-core-stuff-word])').forEach(function (i) {
      i.dataset.gkCoreStuffWord = '1';
      if (i.value === w.from) { i.value = w.to; if (i.dataset.disableWith === w.from) i.dataset.disableWith = w.to; }
    });
  });
})();
