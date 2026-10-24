// gk_core_stuff control_heights.
// A button beside a text field or a list on the same line (a filter, a form's row, an inline form) is often higher or
// lower than the field, and two kinds of field (a date and a text) differ by a border's width. The buttons and fields
// that stand on one line in the same box get the height of the highest of them, on core's pages too. Only min-height is set (with border-box, so that padding is not added); a box whose
// controls stand on different lines is measured per line. Hidden parts are measured when a click may have opened them.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('control_heights')) return;

  var FIELD = 'input:not([type=hidden]):not([type=checkbox]):not([type=radio]):not([type=submit]):not([type=button]):not([type=reset]):not([type=image]):not([type=file]):not([type=range]):not([type=color]), select:not([multiple])';
  var BUTTON = 'input[type=submit], input[type=button], input[type=reset], button';
  // the controls of a box: its own children and those inside its labels and spans, not those in a box of their own
  function controls(box) {
    return Array.prototype.filter.call(box.querySelectorAll(':scope > input, :scope > select, :scope > button, :scope > label > input, :scope > label > select, :scope > span > input, :scope > span > select, :scope > span > button'),
      function (el) { return (el.matches(FIELD) || el.matches(BUTTON)) && !G.skip(el) && el.offsetHeight > 0; });
  }
  function even(box) {
    var all = controls(box);
    if (all.length < 2) return;
    // per line: the controls whose middles stand within a few pixels of each other
    var lines = [];
    all.forEach(function (el) {
      var r = el.getBoundingClientRect(), mid = r.top + r.height / 2;
      var line = lines.find(function (l) { return Math.abs(l.mid - mid) < 8; });
      if (line) line.els.push(el); else lines.push({ mid: mid, els: [el] });
    });
    lines.forEach(function (l) {
      if (l.els.length < 2) return;
      l.els.forEach(function (el) { el.style.minHeight = ''; });
      var hs = l.els.map(function (el) { return el.getBoundingClientRect().height; }), h = Math.max.apply(null, hs);
      if (Math.min.apply(null, hs) >= h - 0.5) return;
      l.els.forEach(function (el, i) {
        if (hs[i] < h - 0.5) { el.style.boxSizing = 'border-box'; el.style.minHeight = h + 'px'; }
      });
    });
  }
  function scan(root) {
    var boxes = new Set();
    (root || document).querySelectorAll(FIELD + ', ' + BUTTON).forEach(function (b) {
      var box = b.parentElement;
      if (box && (box.tagName === 'LABEL' || box.tagName === 'SPAN')) box = box.parentElement;
      if (box) boxes.add(box);
    });
    boxes.forEach(even);
  }
  var timer = null;
  document.addEventListener('click', function () { clearTimeout(timer); timer = setTimeout(function () { scan(document); }, 80); }, true);
  G.onContent(scan);
})();
