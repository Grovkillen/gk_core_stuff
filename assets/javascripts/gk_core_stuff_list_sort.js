// gk_core_stuff list_sort: lists of check boxes core draws in its own order (a tracker's projects and custom fields, a
// custom field's projects) stand in alphabetical order, the projects under their parent. Only the order on the screen
// changes: the same boxes, the same values. A plugin marks a list of its own with data-gk-sort (its items:
// data-gk-sort-item, else its labels).
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('list_sort')) return;

  function lang() { return document.documentElement.lang || undefined; }
  function compare(a, b) { return a.localeCompare(b, lang(), { sensitivity: 'base', numeric: true }); }
  function textOf(el) { return (el.textContent || '').replace(/\s+/g, ' ').trim(); }
  // the items of a parent in alphabetical order; whatever stands between them (a hidden field, a line break) goes with
  // the item before it, and what stands before the first item stays where it is
  function sortItems(items) {
    if (items.length < 2) return;
    var parent = items[0].parentNode;
    if (items.some(function (i) { return i.parentNode !== parent; })) return;
    var groups = items.map(function (it, i) {
      var nodes = [it], n = it.nextSibling, last = i === items.length - 1;
      while (n && n !== items[i + 1]) {
        // after the last item only its own line break and spaces; what follows the list stays after it
        if (last && !(n.nodeType === 3 || n.tagName === 'BR')) break;
        nodes.push(n);
        n = n.nextSibling;
      }
      return { key: textOf(it), nodes: nodes };
    });
    var sorted = groups.slice().sort(function (a, b) { return compare(a.key, b.key); });
    if (sorted.every(function (g, i) { return g === groups[i]; })) return;
    var marker = document.createComment('');
    var tail = groups[groups.length - 1].nodes;
    parent.insertBefore(marker, tail[tail.length - 1].nextSibling);
    sorted.forEach(function (g) { g.nodes.forEach(function (n) { parent.insertBefore(n, marker); }); });
    parent.removeChild(marker);
  }
  // core's nested project list: the projects under each parent in alphabetical order, children kept under theirs
  function sortTree(ul) {
    var lis = Array.prototype.filter.call(ul.children, function (n) { return n.tagName === 'LI'; });
    lis.forEach(function (li) { var sub = li.querySelector(':scope > ul'); if (sub) sortTree(sub); });
    var sorted = lis.slice().sort(function (a, b) {
      var x = a.querySelector(':scope > div'), y = b.querySelector(':scope > div');
      return compare(textOf(x || a), textOf(y || b));
    });
    sorted.forEach(function (li) { ul.appendChild(li); });
  }
  function sorts(root) {
    // a tracker's projects, a custom field's projects
    root.querySelectorAll('#tracker_project_ids > ul.projects.root, #custom_field_project_ids > ul.projects.root').forEach(function (ul) {
      if (ul.dataset.gkCoreStuffSorted) return;
      ul.dataset.gkCoreStuffSorted = '1';
      sortTree(ul);
    });
    // a tracker's custom fields
    root.querySelectorAll('input[name="tracker[custom_field_ids][]"][type=checkbox]').forEach(function (cb) {
      var p = cb.closest('p');
      if (!p || p.dataset.gkCoreStuffSorted) return;
      p.dataset.gkCoreStuffSorted = '1';
      sortItems(Array.prototype.filter.call(p.querySelectorAll(':scope > label'), function (l) { return l.querySelector('input[type=checkbox]'); }));
    });
    root.querySelectorAll('[data-gk-sort]').forEach(function (box) {
      if (box.dataset.gkCoreStuffSorted) return;
      box.dataset.gkCoreStuffSorted = '1';
      var items = box.querySelectorAll(':scope > [data-gk-sort-item]');
      if (!items.length) items = box.querySelectorAll(':scope > label');
      sortItems(Array.prototype.slice.call(items));
    });
  }

  G.onContent(sorts);
})();
