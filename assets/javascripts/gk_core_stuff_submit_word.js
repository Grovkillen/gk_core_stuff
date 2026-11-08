// gk_core_stuff submit_word: core's submit button in the forms that save becomes core's own word for save ("Spara"),
// in whatever language the person has: the word is core's translation, none of ours. The buttons are found by core's
// own anchors, never by their text: the commit button of the issue's edit form (form#issue-form, which Rails marks
// edit_issue for a saved issue; the new-issue form is new_issue and keeps Create) and of the two bulk edit forms
// (form#bulk_edit_form, issues and time entries). The same three forms as the upstream patch.
// issues/bulk_edit renders the same form#bulk_edit_form in three modes, each with a commit button: copy (Copy), move
// (Move) and edit (Submit). Only edit saves, and only its button is in the upstream patch. Copy and move are told
// apart by the parameters core gives them on purpose and its controller reads by name: both have the second submit
// button named "follow" (copy and follow, move and follow), copy also the hidden field "copy". Edit has neither, so a
// bulk edit form with either is left as core renders it.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('submit_word')) return;
  var w = G.opt('submit_word');
  if (!w.to) return;
  var COMMIT = 'input[type="submit"][name="commit"]';
  var NOT_SAVE = 'input[type="submit"][name="follow"],input[type="hidden"][name="copy"]';
  function rename(i) {
    if (i.dataset.gkCoreStuffWord) return;
    i.dataset.gkCoreStuffWord = '1';
    i.value = w.to;
    if (i.dataset.disableWith) i.dataset.disableWith = w.to;
    G.mark(i, 'submit_word');
  }
  // the issue's edit form stands hidden in core's #update until it is opened: the button becomes a place on the page then
  function watchUpdate() {
    var update = document.getElementById('update');
    if (update) new MutationObserver(G.drawn).observe(update, { attributes: true, attributeFilter: ['style'] });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', watchUpdate); else watchUpdate();
  G.onContent(function (root) {
    root.querySelectorAll('form#issue-form.edit_issue ' + COMMIT).forEach(rename);
    root.querySelectorAll('form#bulk_edit_form').forEach(function (f) {
      if (f.querySelector(NOT_SAVE)) return;
      f.querySelectorAll(COMMIT).forEach(rename);
    });
  });
})();
