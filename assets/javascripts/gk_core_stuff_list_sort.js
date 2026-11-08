// gk_core_stuff list_sort: lists of check boxes core draws in its own order (a tracker's projects and custom fields, a
// custom field's projects) stand in alphabetical order, the projects under their parent. Only the order on the screen
// changes: the same boxes, the same values. A plugin marks a list of its own with data-gk-sort (its items:
// data-gk-sort-item, else its labels).
(function () {
  var G = window.gkCoreStuffLooks;
  if (!G || !G.on('list_sort')) return;

  function lang() { return document.documentElement.lang || undefined; }
  function compare(a, b) { return a.localeCompare(b, lang(), { sensitivity: 'base', numeric: true }); }
  // an item's name as the person reads it, only for the order
  function textOf(el) { return (el.textContent || '').replace(/\s+/g, ' ').trim(); } // gk-r17 P4r: sorts by the names administrators gave their projects and fields; no word of Redmine is matched or looked for
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
  // core's nested project list (render_project_nested_lists): the projects under each parent in alphabetical order,
  // children kept under theirs. Found by the classes core gives it on purpose: ul.projects for a list, li.root or
  // li.child for a project, and div.root or div.child for the project's own name; a project's own list and name are
  // the first of their kind inside it, before those of its children.
  var ITEM = 'li.root, li.child', NAME = 'div.root, div.child';
  function sortTree(ul) {
    var lis = Array.prototype.filter.call(ul.children, function (n) { return n.matches(ITEM); });
    lis.forEach(function (li) { var sub = li.querySelector('ul.projects'); if (sub) sortTree(sub); });
    var sorted = lis.slice().sort(function (a, b) {
      var x = a.querySelector(NAME), y = b.querySelector(NAME);
      if (!x || !y) return 0;
      return compare(textOf(x), textOf(y));
    });
    sorted.forEach(function (li) { ul.appendChild(li); });
  }
  // the items of a list of check boxes: the nearest element that holds every box, and of its children the ones that
  // hold a box. Whatever core wraps a box in (a label, a span, a div) goes with it. Exactly one box per item, else null
  // and the list keeps core's order.
  function itemsOf(boxes) {
    if (boxes.length < 2) return null;
    var box = boxes[0].parentElement;
    while (box && !boxes.every(function (b) { return box.contains(b); })) box = box.parentElement;
    if (!box) return null;
    var items = Array.prototype.filter.call(box.children, function (c) { return boxes.some(function (b) { return c.contains(b); }); });
    if (items.length !== boxes.length) return null;
    return { box: box, items: items };
  }
  function sorts(root) {
    // a tracker's projects, a custom field's projects
    root.querySelectorAll('#tracker_project_ids ul.projects.root, #custom_field_project_ids ul.projects.root').forEach(function (ul) {
      if (ul.dataset.gkCoreStuffSorted) return;
      ul.dataset.gkCoreStuffSorted = '1';
      sortTree(ul);
    });
    // a tracker's custom fields: found by the name core gives the boxes (the form's own parameter), never by the tags
    // around them
    var cfs = Array.prototype.slice.call(root.querySelectorAll('input[type=checkbox][name="tracker[custom_field_ids][]"]'));
    var list = itemsOf(cfs);
    if (list && !list.box.dataset.gkCoreStuffSorted) {
      list.box.dataset.gkCoreStuffSorted = '1';
      sortItems(list.items);
    }
    root.querySelectorAll('[data-gk-sort]').forEach(function (box) {
      if (box.dataset.gkCoreStuffSorted) return;
      box.dataset.gkCoreStuffSorted = '1';
      var items = box.querySelectorAll(':scope > [data-gk-sort-item]');
      if (!items.length) items = box.querySelectorAll(':scope > label'); // gk-r17 P2r: the labels of a list a plugin marks as its own with data-gk-sort, the plugin's markup and not core's
      sortItems(Array.prototype.slice.call(items));
    });
  }

  G.onContent(sorts);
})();
