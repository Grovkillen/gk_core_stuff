// gk_core_stuff control_heights.
// A button beside a text field or a list on the same line (a filter, a form's row, an inline form) is often higher or
// lower than the field, and two kinds of field (a date and a text) differ by a border's width. The buttons and fields
// of one form that stand side by side on one line get the height of the highest of them, on core's pages too. The
// controls are grouped by what the browser shows, never by the tags around them: the form a control belongs to (its
// form attribute in HTML), the line its middle stands on, and a gap of at most GAP pixels to the next control on that
// line. Only min-height is set (with border-box, so that padding is not added). Hidden parts are measured when a click
// may have opened them.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('control_heights')) return;

  var FIELD = 'input:not([type=hidden]):not([type=checkbox]):not([type=radio]):not([type=submit]):not([type=button]):not([type=reset]):not([type=image]):not([type=file]):not([type=range]):not([type=color]), select:not([multiple])';
  var BUTTON = 'input[type=submit], input[type=button], input[type=reset], button';
  var GAP = 24;

  function even(els) {
    if (els.length < 2) return;
    els.forEach(function (el) { el.style.minHeight = ''; });
    var hs = els.map(function (el) { return el.getBoundingClientRect().height; }), h = Math.max.apply(null, hs);
    els.forEach(function (el, i) {
      if (hs[i] < h - 0.5) { el.style.boxSizing = 'border-box'; el.style.minHeight = h + 'px'; G.mark(el, 'control_heights'); }
      else G.unmark(el, 'control_heights');
    });
  }
  function scan(root) {
    var forms = new Map();
    (root || document).querySelectorAll(FIELD + ', ' + BUTTON).forEach(function (el) {
      if (G.skip(el) || el.offsetHeight <= 0) return;
      var key = el.form || null;
      if (!forms.has(key)) forms.set(key, []);
      forms.get(key).push(el);
    });
    forms.forEach(function (els) {
      // per line: the controls whose middles stand within a few pixels of each other
      var lines = [];
      els.forEach(function (el) {
        var r = el.getBoundingClientRect(), mid = r.top + r.height / 2;
        var line = lines.find(function (l) { return Math.abs(l.mid - mid) < 8; });
        if (line) line.items.push({ el: el, r: r }); else lines.push({ mid: mid, items: [{ el: el, r: r }] });
      });
      // on a line, the controls side by side: a wider gap starts another group
      lines.forEach(function (l) {
        l.items.sort(function (a, b) { return a.r.left - b.r.left; });
        var run = [];
        l.items.forEach(function (it, i) {
          if (i && it.r.left - l.items[i - 1].r.right > GAP) { even(run); run = []; }
          run.push(it.el);
        });
        even(run);
      });
    });
  }
  var timer = null;
  document.addEventListener('click', function () { clearTimeout(timer); timer = setTimeout(function () { scan(document); }, 80); }, true);
  G.onContent(scan);
})();
