// gk_core_stuff list_align.
// Core centres every heading in a list (table.list th). A heading whose column's cells all stand at the start (or all
// at the end) is set the same way; a column of centred cells, or of mixed ones, keeps core's centred heading.
// Only the heading's alignment changes, never a cell.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('list_align')) return;

  function side(el) {
    var a = window.getComputedStyle(el).textAlign, rtl = window.getComputedStyle(el).direction === 'rtl';
    if (a === 'start' || a === (rtl ? 'right' : 'left')) return 'start';
    if (a === 'end' || a === (rtl ? 'left' : 'right')) return 'end';
    return 'center';
  }

  G.onContent(function (root) {
    root.querySelectorAll('table.list').forEach(function (table) {
      if (table.dataset.gkCoreStuffAlign) return;
      table.dataset.gkCoreStuffAlign = '1';
      var head = table.tHead && table.tHead.rows[table.tHead.rows.length - 1];
      if (!head) return;
      // a heading row with spans does not line up with the cells by index: left as core has it
      for (var i = 0; i < head.cells.length; i++) if (head.cells[i].colSpan > 1) return;
      var rows = [];
      Array.prototype.forEach.call(table.tBodies, function (b) {
        Array.prototype.forEach.call(b.rows, function (r) { if (rows.length < 8 && r.cells.length === head.cells.length) rows.push(r); });
      });
      if (!rows.length) return;
      Array.prototype.forEach.call(head.cells, function (th, i) {
        // a column of descriptions or long texts reads from the start, its cells and its heading
        var texts = rows.map(function (r) { return r.cells[i].textContent.trim(); }).filter(Boolean);
        var long = texts.length && texts.reduce(function (n, t) { return n + t.length; }, 0) / texts.length > 40;
        if (long || rows.some(function (r) { return r.cells[i].classList.contains('description'); })) {
          table.querySelectorAll('tbody tr').forEach(function (r) { if (r.cells.length === head.cells.length) r.cells[i].style.textAlign = 'start'; });
          th.style.textAlign = 'start';
          return;
        }
        if (side(th) !== 'center') return;
        var sides = rows.map(function (r) { return r.cells[i].textContent.trim() === '' ? null : side(r.cells[i]); }).filter(Boolean);
        if (!sides.length || sides.some(function (s) { return s !== sides[0]; }) || sides[0] === 'center') return;
        th.style.textAlign = sides[0];
      });
    });
  });
})();
