// gk_core_stuff ajax_indicator: core's "Laddar..." box is core's, unchanged, but when what is loading was asked for
// from a list (the row menu, a change of the marked rows) the box stands in the middle of that list, on the marked row
// or rows, instead of in the middle of the window. Anywhere else it stands where core puts it.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('ajax_indicator')) return;
  var place = function (ind) {
    var shown = window.getComputedStyle(ind).display !== 'none';
    var rows = shown ? document.querySelectorAll('table.list tr.context-menu-selection') : [];
    if (!rows.length) {
      if (ind.dataset.gkCoreStuffPlaced) { delete ind.dataset.gkCoreStuffPlaced; ind.style.left = ''; ind.style.top = ''; }
      return;
    }
    var table = rows[0].closest('table').getBoundingClientRect();
    var top = Infinity, bottom = -Infinity;
    rows.forEach(function (r) { var b = r.getBoundingClientRect(); top = Math.min(top, b.top); bottom = Math.max(bottom, b.bottom); });
    // the part of the marked rows that is on the screen; none of it there: the list's own middle on the screen
    top = Math.max(top, 0); bottom = Math.min(bottom, window.innerHeight);
    if (bottom <= top) { top = Math.max(table.top, 0); bottom = Math.min(table.bottom, window.innerHeight); }
    var x = Math.round((Math.max(table.left, 0) + Math.min(table.right, window.innerWidth)) / 2), y = Math.round((top + bottom) / 2);
    if (ind.dataset.gkCoreStuffPlaced === x + ',' + y) return;
    ind.dataset.gkCoreStuffPlaced = x + ',' + y;
    ind.style.left = x + 'px'; ind.style.top = y + 'px'; // core's own translate(-50%, -50%) centres the box on the point
  };
  var watch = function () {
    var ind = document.getElementById('ajax-indicator');
    if (!ind || ind.dataset.gkCoreStuffWatch) return;
    ind.dataset.gkCoreStuffWatch = '1';
    // core shows the box a moment before it marks the row: placed at once and again when the row is marked
    new MutationObserver(function () { place(ind); [0, 40, 120].forEach(function (ms) { setTimeout(function () { place(ind); }, ms); }); })
      .observe(ind, { attributes: true, attributeFilter: ['style'] });
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', watch); else watch();
})();
