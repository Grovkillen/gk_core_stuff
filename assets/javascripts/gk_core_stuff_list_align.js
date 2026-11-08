// gk_core_stuff list_align.
// Core centres every heading in a list (table.list th). A heading whose column's cells all stand at the start (or all
// at the end) is set the same way; a column of centred cells, or of mixed ones, keeps core's centred heading.
// A column is known by the class core gives both its heading and its cells (QueriesHelper#column_header and the
// lists' cells: the column's css_classes, such as subject, cf_3 string), never by its place or its words; a heading
// without such a class is left as core has it. A column of descriptions or texts (core's classes description,
// last_notes, comments, and a custom field of the formats string, text or link) reads from the start, its cells and
// its heading. Only the heading's alignment changes, and the cells of a column of texts.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('list_align')) return;

  var TEXTS = ['description', 'last_notes', 'comments', 'string', 'text', 'link'];

  // the alignment the browser gives a cell or a heading, by the column's own styles
  function side(el) {
    var a = window.getComputedStyle(el).textAlign, rtl = window.getComputedStyle(el).direction === 'rtl';
    if (a === 'start' || a === (rtl ? 'right' : 'left')) return 'start';
    if (a === 'end' || a === (rtl ? 'left' : 'right')) return 'end';
    return 'center';
  }
  // an empty cell says nothing about its column (no word is read, only whether there is any)
  function blank(cell) { return !cell.textContent.trim(); }

  G.onContent(function (root) {
    root.querySelectorAll('table.list').forEach(function (table) {
      if (table.dataset.gkCoreStuffAlign) return;
      table.dataset.gkCoreStuffAlign = '1';
      if (!table.tHead) return;
      table.tHead.querySelectorAll('th[class]').forEach(function (th) {
        var key = th.classList[0];
        if (!key) return;
        // the column's cells: the body's cells with the heading's class
        var cells = [];
        Array.prototype.forEach.call(table.tBodies, function (b) {
          Array.prototype.forEach.call(b.rows, function (r) {
            Array.prototype.forEach.call(r.cells, function (c) { if (c.tagName === 'TD' && c.classList.contains(key)) cells.push(c); });
          });
        });
        if (!cells.length) return;
        if (TEXTS.some(function (t) { return th.classList.contains(t); })) {
          cells.forEach(function (c) { c.style.textAlign = 'start'; });
          th.style.textAlign = 'start';
          G.mark(th, 'list_align');
          return;
        }
        if (side(th) !== 'center') return;
        var sides = cells.slice(0, 8).filter(function (c) { return !blank(c); }).map(side);
        if (!sides.length || sides.some(function (s) { return s !== sides[0]; }) || sides[0] === 'center') return;
        th.style.textAlign = sides[0];
        G.mark(th, 'list_align');
      });
    });
  });
})();
