// gk_core_stuff looks: what the looks' scripts share until core has their fixes. The server sends which looks are on
// for this person, their texts and their values (script#gk-core-stuff-looks). One content observer: a look registers
// an idempotent function with onContent and gets the document once it is ready and again (a moment later) when core
// or a plugin adds something to the page. Nodes of our own (class gk-core-stuff-*) never start a new pass. An element
// with data-gk-looks-skip, and what is inside it, is another script's own control and is left alone. Plain DOM.
window.gkCoreStuffLooks = (function () {
  var el = document.getElementById('gk-core-stuff-looks'), cfg = {};
  try { cfg = JSON.parse(el.textContent); } catch (e) { cfg = { looks: [] }; }
  var fns = [], timer = null, ready = document.readyState !== 'loading';

  function run() {
    timer = null;
    fns.forEach(function (f) { try { f(document); } catch (e) { if (window.console) console.error('[gk_core_stuff]', e); } });
  }
  function schedule() { if (!timer) timer = setTimeout(run, 60); }
  function start() {
    ready = true;
    run();
    new MutationObserver(function (list) {
      for (var i = 0; i < list.length; i++) {
        for (var j = 0; j < list[i].addedNodes.length; j++) {
          var n = list[i].addedNodes[j];
          if (n.nodeType === 1 && !/(^|\s)gk-core-stuff-/.test(typeof n.className === 'string' ? n.className : '')) { schedule(); return; }
        }
      }
    }).observe(document.getElementById('content') || document.body, { childList: true, subtree: true });
  }
  if (ready) setTimeout(start, 0); else document.addEventListener('DOMContentLoaded', start);

  return {
    on: function (key) { return (cfg.looks || []).indexOf(key) >= 0; },
    opt: function (key) { return (cfg.opt && cfg.opt[key]) || {}; },
    t: function (key, vars) {
      var s = (cfg.t && cfg.t[key]) || key;
      Object.keys(vars || {}).forEach(function (k) { s = s.replace('%{' + k + '}', vars[k]); });
      return s;
    },
    skip: function (node) { return !!(node && node.closest && node.closest('[data-gk-looks-skip]')); },
    node: function (tag, cls, text) {
      var n = document.createElement(tag);
      if (cls) n.className = cls;
      if (text != null) n.textContent = text;
      return n;
    },
    onContent: function (fn) { fns.push(fn); if (ready && !timer) { try { fn(document); } catch (e) { /* the next pass */ } } }
  };
})();
