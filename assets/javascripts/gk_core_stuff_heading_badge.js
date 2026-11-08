// gk_core_stuff heading_badge: the stylesheet moves the badges after a page's heading; this only sets the effect mark on
// them, so that what marks a saved setting's places can find them. The same badges as the stylesheet's: the classes core
// gives them on purpose (badge-status-open, badge-status-closed, badge-private) on the issue page, outside the issue's
// box and its history, where core uses the same classes for other things.
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('heading_badge')) return;
  var PAGE = '.controller-issues.action-show #content ';
  var BADGES = [PAGE + '.badge-status-open', PAGE + '.badge-status-closed', PAGE + '.badge-private'].join(', ');
  G.onContent(function (root) {
    root.querySelectorAll(BADGES).forEach(function (b) {
      if (!b.closest('.issue, #history')) G.mark(b, 'heading_badge');
    });
  });
})();
