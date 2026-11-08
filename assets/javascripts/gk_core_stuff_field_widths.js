// gk_core_stuff field_widths and settings_widths.
// field_widths: lists and text fields that stand straight under each other in a form, one per line, get the width of
// the widest of them, so that they read as one column. The fields are found by what the browser shows, never by the
// tags around them: the form a field belongs to (its form in HTML) and its fieldset, the order of the fields, a field
// alone on its line (a button beside it is fine), and the same start edge as the field above it. A text area, a check
// box or a radio button, or another script's own control, between them ends the run, as does a field that starts
// elsewhere or stands right beside another field on its line; the fields elsewhere keep their own widths. Fields in
// another column of the same line (core's two-column issue form) do not count as beside it, so each column is a run. A field that fills the
// box it stands in is left as it is and does not set the width. In a table in a form the fields alone in their cells
// of one column (the cells that start at the same edge) are one run.
// settings_widths: on core's settings pages (body.controller-settings, .box.tabular.settings) every list and text
// field alone on its line in one box (or one fieldset of it) gets one width, whatever stands between them; a field core
// makes short on purpose (a size under 10) keeps its width.
// Only min-width is set, never a field's own width, and never more than the box has room for. Fields in a part not
// shown yet (another tab, a closed box) are measured once they show.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G) return;
  var rows = G.on('field_widths'), settings = G.on('settings_widths');
  if (!rows && !settings) return;

  var SKIP = /^(hidden|checkbox|radio|submit|button|reset|image|file|color|range)$/i;
  var BREAK = /^(checkbox|radio)$/i;
  var GAP = 24;

  // a list or text field of its own: another script's own control (data-gk-looks-skip, such as a searchable chooser
  // and the list it stands for) is not one
  function isField(el) {
    if (G.skip(el)) return false;
    return el.tagName === 'SELECT' || (el.tagName === 'INPUT' && !SKIP.test(el.type || 'text'));
  }
  function fields(box) { return Array.prototype.filter.call(box.querySelectorAll('select, input'), isField); }
  function visible(el) { return el.offsetWidth > 0 && el.offsetHeight > 0; }
  function startEdge(el, r) { return window.getComputedStyle(el).direction === 'rtl' ? r.right : r.left; }

  // the controls that count for a run, in the page's order, each with its kind: field (a list or text field alone on
  // its line) or end (anything that ends a run: a text area, a check box, a radio button, a script's own control, or a
  // field sharing its line with another field)
  function controlsOf(els) {
    var items = [];
    els.forEach(function (el) {
      if (!visible(el)) return;
      var kind = null;
      if (isField(el)) kind = 'field';
      else if (el.tagName === 'TEXTAREA' || G.skip(el) || (el.tagName === 'INPUT' && BREAK.test(el.type))) kind = 'end';
      if (kind) items.push({ el: el, kind: kind, r: el.getBoundingClientRect() });
    });
    // a field shares its line only with a control right beside it (at most GAP px between them); a control further off
    // on the same line stands in another column (core's two-column issue form) and leaves the field alone in its own
    items.forEach(function (it) {
      if (it.kind !== 'field') return;
      var mid = it.r.top + it.r.height / 2;
      var shared = items.some(function (o) {
        if (o === it || Math.abs(o.r.top + o.r.height / 2 - mid) >= 8) return false;
        return Math.max(it.r.left, o.r.left) - Math.min(it.r.right, o.r.right) <= GAP;
      });
      if (shared) it.kind = 'end';
    });
    return items;
  }

  // the room a field has in the box it stands in: the box's width less its padding (core's tabular rows keep the
  // label's place as padding)
  function room(el) {
    var p = el.parentElement, cs = window.getComputedStyle(p);
    return p.clientWidth - (parseFloat(cs.paddingLeft) || 0) - (parseFloat(cs.paddingRight) || 0);
  }
  function apply(group) {
    var w = group.map(function (f) { return f.getBoundingClientRect().width; });
    if (w.some(function (x) { return !x; })) return false;
    // a field that fills its box (width 100% or so, like the issue's subject) neither sets nor takes the width; in a
    // table's column the widest field gives the cells their width, so there no field counts as filling
    var fill = group.map(function (f, i) { var p = room(f); return !group.column && p > 0 && w[i] >= p * 0.9; });
    var target = 0;
    group.forEach(function (f, i) { if (!fill[i] && w[i] > target) target = w[i]; });
    if (!target) return true;
    // never wider than the box: a narrower window (or a box that shrinks) keeps the field inside it
    group.forEach(function (f, i) {
      if (fill[i] || w[i] >= target - 0.5) return;
      f.style.minWidth = 'min(' + Math.ceil(target) + 'px, 100%)';
      G.mark(f, group.look || 'field_widths');
    });
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

  // core's settings: one width per box or fieldset of a box
  function settingsBoxes(root) {
    if (!document.body.classList.contains('controller-settings')) return;
    root.querySelectorAll('.box.tabular.settings').forEach(function (box) {
      var parts = new Map();
      controlsOf(Array.prototype.slice.call(box.querySelectorAll('input, select, textarea'))).forEach(function (it) {
        if (it.kind !== 'field' || (it.el.tagName === 'INPUT' && Number(it.el.getAttribute('size') || 99) < 10)) return;
        // a field of a fieldset inside the box belongs to the fieldset
        var part = it.el.closest('fieldset, .box.tabular.settings');
        if (!parts.has(part)) parts.set(part, []);
        parts.get(part).push(it.el);
      });
      parts.forEach(function (group) { group.look = 'settings_widths'; take(group); });
    });
  }

  // a form's fields straight under each other, per form and fieldset; the fields in a table's cells belong to the
  // table's columns (below)
  function runs(root) {
    var groups = new Map();
    root.querySelectorAll('input, select, textarea').forEach(function (el) {
      if (!el.form || el.closest('td, th')) return;
      var key = el.closest('fieldset') || el.form;
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push(el);
    });
    groups.forEach(function (els) {
      var run = [], last = null;
      controlsOf(els).forEach(function (it) {
        if (it.kind !== 'field') { take(run); run = []; last = null; return; }
        var edge = startEdge(it.el, it.r);
        if (last && (Math.abs(edge - last.edge) > 1 || it.r.top < last.r.bottom - 1)) { take(run); run = []; }
        run.push(it.el);
        last = { edge: edge, r: it.r };
      });
      take(run);
    });
  }

  // a column of a table in a form (the modes of a list of modules, a list's own names): the one list or text field
  // alone in each cell of the column (the cells that start at the same edge) gets the width of the widest
  function columns(root) {
    root.querySelectorAll('form table').forEach(function (table) {
      var cols = {};
      Array.prototype.forEach.call(table.tBodies, function (body) {
        Array.prototype.forEach.call(body.rows, function (tr) {
          Array.prototype.forEach.call(tr.cells, function (td) {
            if (!visible(td)) return;
            var f = fields(td);
            if (f.length !== 1 || td.querySelector('textarea')) return;
            var k = Math.round(startEdge(td, td.getBoundingClientRect()));
            (cols[k] = cols[k] || []).push(f[0]);
          });
        });
      });
      Object.keys(cols).forEach(function (k) { cols[k].column = true; take(cols[k]); });
    });
  }

  function scan(root) {
    if (settings) settingsBoxes(root);
    if (!rows) return;
    runs(root);
    columns(root);
  }
  // a tab or a box opened by a click shows fields that could not be measured before
  var timer = null;
  document.addEventListener('click', function () { clearTimeout(timer); timer = setTimeout(function () { scan(document); }, 80); }, true);
  G.onContent(scan);
})();
