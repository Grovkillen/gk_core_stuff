// gk_core_stuff field_widths and settings_widths.
// field_widths: lists and text fields that stand straight under each other in a form, one per row, get the width of
// the widest of them, so that they read as one column. A row is a paragraph with one such field (core's tabular
// forms); an explaining text (em.info) in a row does not end the run, but a heading, a section or a row of another
// kind between them does, and the fields elsewhere keep their own widths. A field that fills its row is left as it is
// and does not set the width. In a table in a form the fields standing right in the cells of one column are one run.
// settings_widths: on core's settings pages every list and text field in one box (or one section of it) gets one
// width, whatever stands between them; a field core makes short on purpose (a size under 10) keeps its width.
// Only min-width is set, never a field's own width, and never more than the row has room for. Rows in a part not shown yet (another tab, a closed box) are
// measured once they show.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G) return;
  var rows = G.on('field_widths'), settings = G.on('settings_widths');
  if (!rows && !settings) return;

  var SKIP = /^(hidden|checkbox|radio|submit|button|reset|image|file|color|range)$/i;

  // another script's own control (data-gk-looks-skip, such as a searchable chooser and the list it stands for) keeps its width
  function fields(row) {
    return Array.prototype.filter.call(row.querySelectorAll('select, input'), function (el) {
      if (G.skip(el)) return false;
      return el.tagName === 'SELECT' || !SKIP.test(el.type || 'text');
    });
  }
  // shown by itself: a row in a hidden tab still counts (its own display is not none), a row hidden on its own does not
  function shown(el) { return el.hidden !== true && window.getComputedStyle(el).display !== 'none'; }
  // the row's one field, or null when the row has none, several or other controls (a textarea, a check box)
  function single(row) {
    if (row.tagName !== 'P') return null;
    var f = fields(row);
    if (f.length !== 1 || row.querySelector('textarea, input[type=checkbox], input[type=radio]')) return null;
    return f[0];
  }

  // the room a field has in its row: the row's width less its padding (core's tabular rows keep the label's place
  // as padding)
  function room(el) {
    var p = el.parentElement, cs = window.getComputedStyle(p);
    return p.clientWidth - (parseFloat(cs.paddingLeft) || 0) - (parseFloat(cs.paddingRight) || 0);
  }
  function apply(group) {
    var w = group.map(function (f) { return f.getBoundingClientRect().width; });
    if (w.some(function (x) { return !x; })) return false;
    // a field that fills its row (width 100% or so, like the issue's subject) neither sets nor takes the width; in a
    // table's column the widest field gives the cells their width, so there no field counts as filling
    var fill = group.map(function (f, i) { var p = room(f); return !group.column && p > 0 && w[i] >= p * 0.9; });
    var target = 0;
    group.forEach(function (f, i) { if (!fill[i] && w[i] > target) target = w[i]; });
    if (!target) return true;
    // never wider than the row: a narrower window (or a row that shrinks) keeps the field inside it
    group.forEach(function (f, i) { if (!fill[i] && w[i] < target - 0.5) f.style.minWidth = 'min(' + Math.ceil(target) + 'px, 100%)'; });
    return true;
  }

  // a group in a part not shown yet (a closed box, another tab) is measured once it shows
  var waiting = 'IntersectionObserver' in window ? new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (!e.isIntersecting && !e.target.offsetWidth) return;
      var g = e.target._gkFieldGroup;
      if (g && apply(g)) { waiting.unobserve(e.target); e.target._gkFieldGroup = null; }
    });
  }) : null;

  function take(group) {
    if (group.length < 2 || group.some(function (f) { return f.dataset.gkCoreStuffWidth; })) return;
    group.forEach(function (f) { f.dataset.gkCoreStuffWidth = '1'; });
    if (!apply(group) && waiting) { group[0]._gkFieldGroup = group; waiting.observe(group[0]); }
  }

  // core's settings: one width per box or section of a box
  function settingsBoxes(root) {
    if (!document.body.classList.contains('controller-settings')) return;
    root.querySelectorAll('.box.tabular.settings').forEach(function (box) {
      var parts = [box].concat(Array.prototype.slice.call(box.querySelectorAll('fieldset')));
      parts.forEach(function (part) {
        var group = [];
        part.querySelectorAll('p').forEach(function (row) {
          // a row of a section inside this part belongs to the section
          var owner = row.parentElement.closest('fieldset, .box.tabular.settings');
          if (owner !== part || !shown(row)) return;
          var f = single(row);
          if (!f || (f.tagName === 'INPUT' && Number(f.getAttribute('size') || 99) < 10)) return;
          group.push(f);
        });
        take(group);
      });
    });
  }

  G.onContent(function (root) {
    if (settings) settingsBoxes(root);
    if (!rows) return;
    var seen = new Set();
    root.querySelectorAll('form p').forEach(function (row) {
      if (seen.has(row) || !single(row) || !shown(row)) return;
      // the start of a run: the row before it is not of the kind
      var prev = row.previousElementSibling;
      while (prev && !shown(prev)) prev = prev.previousElementSibling;
      if (prev && single(prev)) return;
      var group = [];
      for (var r = row; r; r = r.nextElementSibling) {
        if (!shown(r)) continue;
        var f = single(r);
        if (!f) break;
        seen.add(r);
        group.push(f);
      }
      take(group);
    });
    // a column of a table in a form (the modes of a list of modules, a list's own names): the one list or text field
    // that stands right in each cell of the column gets the width of the widest; a field inside a part of its own in
    // the cell keeps its width
    root.querySelectorAll('form table').forEach(function (table) {
      var cols = {};
      Array.prototype.forEach.call(table.tBodies, function (body) {
        Array.prototype.forEach.call(body.rows, function (tr) {
          if (!shown(tr)) return;
          Array.prototype.forEach.call(tr.cells, function (td) {
            var f = fields(td);
            if (f.length !== 1 || f[0].parentElement !== td || td.querySelector('textarea')) return;
            (cols[td.cellIndex] = cols[td.cellIndex] || []).push(f[0]);
          });
        });
      });
      Object.keys(cols).forEach(function (k) { cols[k].column = true; take(cols[k]); });
    });
  });
})();
