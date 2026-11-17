// gk_core_stuff chart_colors: Redmine's own charts in the colours of the surface that is drawn
// (modules/chart_colors/module.rb). While the page is dark (GK Core Stuff's dark mode class on html) or a theme says the
// tone of its surface (GK GUI Stuff's tone attribute on html), core's Chart.js charts take the category roles in order,
// starting over after ten: the edge in the role, the fill in its soft tone; text, grid, axes and tooltip take their
// roles. The revision graph and the marks in the Gantt chart's drawing keep their hues, each mark at a lightness that
// holds 3:1 against the surface it stands on. The Gantt chart's today line, which core names by an id and whose colour
// core gives the progress line, is held by the same rule on the element itself. In the light without a theme nothing is
// touched; when the mode changes on an open page, what was changed is put back or drawn again.
// No colour stands here: the roles come by name from the server and are resolved on the page. Core's charts are found
// by their canvas ids and Chart.js's own API (Chart.register, Chart.instances, each chart's config); the graphs by the
// revision graph's class, the Gantt drawing's id and the today line's id. How Chart.js is reached (a module through the
// import map, or the global Chart) is GK Compat's answer, sent as opt.module.
(function () {
  var G = window.gkCoreStuffLooks;
  var KEY = 'chart_colors';
  if (!G || !G.on(KEY)) return;
  var o = G.opt(KEY), R = o.roles;
  if (!R || !R.series || !R.series.length) return;
  var html = document.documentElement;
  var PLUGIN = 'gk_core_stuff_chart_colors';
  var saved = new WeakMap();   // chart: what stood at each path before (by path from chart.config), put back in the light
  var painted = new Set();     // the charts changed now
  var library = null, registered = false;

  // The surface is dark or toned: GK Core Stuff's dark mode, or a theme that says its tone
  function active() {
    if (o.tone && html.hasAttribute(o.tone)) return true;
    return !!(o.dark && html.classList.contains(o.dark));
  }

  // A role's value as the page resolves it now, in a form a canvas takes; null when the role is not there
  var probe = null;
  function color(name) {
    if (!name || !getComputedStyle(html).getPropertyValue(name).trim()) return null;
    if (!probe) {
      probe = document.createElement('span');
      probe.className = 'gk-core-stuff-chart-colors-probe';
      probe.style.display = 'none';
      document.body.appendChild(probe);
    }
    probe.style.color = '';
    probe.style.color = 'var(' + name + ')';
    return getComputedStyle(probe).color;
  }

  function isCore(chart) {
    var c = chart && chart.canvas;
    return !!(c && c.id && o.charts.indexOf(c.id) >= 0);
  }
  function coreCanvases() {
    return o.charts.map(function (id) { return document.getElementById(id); }).filter(Boolean);
  }

  // The object and key a path from chart.config names, walked anew on every call: Chart.js replaces the scales' options
  // with fresh copies on each update, so an object kept from an earlier pass may no longer be the live one. With make,
  // missing objects on the way are created and their paths listed in made
  function at(chart, path, make, made) {
    var keys = path.split('.'), last = keys.pop(), cur = chart.config, walked = [];
    for (var i = 0; i < keys.length; i++) {
      var k = keys[i];
      walked.push(k);
      if (cur[k] == null || typeof cur[k] !== 'object') {
        if (!make) return null;
        cur[k] = {};
        if (made) made.push(walked.join('.'));
      }
      cur = cur[k];
    }
    return { obj: cur, key: last };
  }
  // Set the path to value, keeping what stood there the first time
  function put(chart, path, value) {
    if (value == null) return;
    var m = saved.get(chart);
    if (!m) { m = { paths: Object.create(null), made: [] }; saved.set(chart, m); }
    var made = [], p = at(chart, path, true, made);
    made.forEach(function (q) { if (m.made.indexOf(q) < 0) m.made.push(q); });
    if (!(path in m.paths)) m.paths[path] = { had: Object.prototype.hasOwnProperty.call(p.obj, p.key), value: p.obj[p.key] };
    p.obj[p.key] = value;
  }
  // Put back what stood at each path, on the live objects, and take away the empty objects this script made
  function putBack(chart) {
    var m = saved.get(chart);
    if (!m) return false;
    Object.keys(m.paths).forEach(function (path) {
      var e = m.paths[path], p = at(chart, path, false);
      if (!p) return;
      if (e.had) p.obj[p.key] = e.value; else delete p.obj[p.key];
    });
    m.made.slice().sort(function (a, b) { return b.split('.').length - a.split('.').length; }).forEach(function (path) {
      var p = at(chart, path, false), v = p && p.obj[p.key];
      if (v && typeof v === 'object' && !Object.keys(v).length) delete p.obj[p.key];
    });
    saved.delete(chart);
    return true;
  }

  // The ids of the chart's scales: the built ones, and before the first build the configured ones and the axis
  // letter Chart.js gives an axis no configured scale names
  function scaleIds(chart, opts) {
    var ids = Object.keys(chart.scales || {});
    var conf = opts.scales || {};
    Object.keys(conf).forEach(function (id) { if (ids.indexOf(id) < 0) ids.push(id); });
    ['x', 'y'].forEach(function (axis) {
      var named = ids.some(function (id) {
        var s = conf[id] || {};
        return id === axis || s.axis === axis || (!s.axis && id.charAt(0).toLowerCase() === axis);
      });
      if (!named) ids.push(axis);
    });
    return ids;
  }

  // The roles on one chart's own config; Chart.js reads them on the next update
  function paint(chart) {
    var cfg = chart.config, opts = cfg.options || (cfg.options = {});
    var text = color(R.text), grid = color(R.grid), axis = color(R.axis), tip = color(R.tip), tipText = color(R.tip_text);
    (cfg.data && cfg.data.datasets || []).forEach(function (ds, i) {
      var pair = R.series[i % R.series.length];
      put(chart, 'data.datasets.' + i + '.borderColor', color(pair[0]));
      put(chart, 'data.datasets.' + i + '.backgroundColor', color(pair[1]));
    });
    put(chart, 'options.color', text);
    put(chart, 'options.plugins.title.color', text);
    put(chart, 'options.plugins.legend.labels.color', text);
    put(chart, 'options.plugins.tooltip.backgroundColor', tip);
    put(chart, 'options.plugins.tooltip.titleColor', tipText);
    put(chart, 'options.plugins.tooltip.bodyColor', tipText);
    put(chart, 'options.plugins.tooltip.footerColor', tipText);
    scaleIds(chart, opts).forEach(function (id) {
      var s = 'options.scales.' + id + '.';
      put(chart, s + 'ticks.color', text);
      put(chart, s + 'title.color', text);
      put(chart, s + 'grid.color', grid);
      // both the older and the newer name of the axis line are set; Chart.js ignores the one it does not know
      put(chart, s + 'grid.borderColor', axis);
      put(chart, s + 'border.color', axis);
    });
    painted.add(chart);
    if (chart.canvas) G.mark(chart.canvas, 'chart_colors');
  }
  function unpaint(chart) {
    painted.delete(chart);
    if (chart.canvas) G.unmark(chart.canvas, 'chart_colors');
    return putBack(chart);
  }

  // Chart.js as the running Redmine loads it: the module through the import map, or the global a classic script set
  function chartJs() {
    if (!o.module) return Promise.resolve(window.Chart || null);
    if (!library) library = import('chart.js').then(function (m) { return m.default || m.Chart || null; }, function () { return null; });
    return library;
  }
  function instances(Chart) {
    var all = Chart && Chart.instances;
    return all ? Object.keys(all).map(function (k) { return all[k]; }) : [];
  }

  // The roles' values as the page resolves them now, so that a chart is updated only when they changed
  var drawnWith = new WeakMap();
  function signature() {
    var names = [R.text, R.grid, R.axis, R.tip, R.tip_text];
    R.series.forEach(function (pair) { names.push(pair[0], pair[1]); });
    return names.map(color).join('|');
  }

  function charts() {
    var on = active();
    if (!on && !painted.size) return;
    if (!coreCanvases().length) return;
    chartJs().then(function (Chart) {
      if (!Chart) return;
      if (on && !registered && Chart.register) {
        // a chart core creates from now on gets the roles on its config before its first update; a destroyed chart
        // is let go
        Chart.register({
          id: PLUGIN,
          afterInit: function (chart) { if (isCore(chart) && active()) { paint(chart); drawnWith.set(chart, signature()); } },
          afterDestroy: function (chart) { painted.delete(chart); saved.delete(chart); drawnWith.delete(chart); }
        });
        registered = true;
      }
      var now = active(), sig = now ? signature() : '', live = instances(Chart);
      // a chart that is no longer among Chart.js's instances is let go as well
      painted.forEach(function (chart) { if (live.indexOf(chart) < 0) painted.delete(chart); });
      live.filter(isCore).forEach(function (chart) {
        // drawn again only when the roles' values changed since its last pass, or when it goes back to core's colours
        if (now && drawnWith.get(chart) === sig) return;
        var changed = now ? (paint(chart), true) : unpaint(chart);
        if (now) drawnWith.set(chart, sig); else drawnWith.delete(chart);
        if (changed && chart.update) chart.update('none');
      });
    });
  }

  // The graphs: each mark keeps its hue, at a lightness that holds 3:1 against the surface. Written as the element's
  // own style, so the attribute core drew stays as it was and comes back in the light
  function parseColour(s) {
    var m = /rgba?\(\s*([\d.]+)[ ,]+([\d.]+)[ ,]+([\d.]+)(?:[ ,/]+([\d.]+%?))?/.exec(s || '');
    if (!m) return null;
    var a = m[4] == null ? 1 : (m[4].slice(-1) === '%' ? parseFloat(m[4]) / 100 : parseFloat(m[4]));
    return { r: +m[1], g: +m[2], b: +m[3], a: a };
  }
  function lum(c) {
    function ch(v) { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }
  function ratio(a, b) { var x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); }
  function toHsl(c) {
    var r = c.r / 255, g = c.g / 255, b = c.b / 255, max = Math.max(r, g, b), min = Math.min(r, g, b), l = (max + min) / 2, h = 0, s = 0;
    if (max !== min) {
      var d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      h = max === r ? (g - b) / d + (g < b ? 6 : 0) : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
      h *= 60;
    }
    return { h: h, s: s, l: l };
  }
  function fromHsl(h, s, l) {
    function f(n) { var k = (n + h / 30) % 12, a = s * Math.min(l, 1 - l); return Math.round(255 * (l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)))); }
    return { r: f(0), g: f(8), b: f(4), a: 1 };
  }
  // the worked-out colour written as six hex digits
  function css(c) { return '#' + [c.r, c.g, c.b].map(function (v) { return (256 + v).toString(16).slice(1); }).join(''); }
  // The same hue and saturation, a step of lightness at a time in one direction, until it holds the contrast or the
  // lightness runs out
  var STEP = 0.01;
  function walk(x, ground, step) {
    var l = x.l, next = fromHsl(x.h, x.s, l);
    while (ratio(next, ground) < o.contrast && l > 0 && l < 1) {
      l = Math.max(0, Math.min(1, l + step));
      next = fromHsl(x.h, x.s, l);
    }
    return next;
  }
  // Lighter on a dark surface and darker on a light one first; when that does not hold the contrast the other way
  // too, and the one with the higher ratio is taken. When neither holds it, that is said once in the console
  var warned = false;
  function holding(c, ground) {
    if (ratio(c, ground) >= o.contrast) return null;
    var x = toHsl(c), first = lum(ground) < 0.18 ? STEP : -STEP;
    var best = walk(x, ground, first);
    if (ratio(best, ground) < o.contrast) {
      var other = walk(x, ground, -first);
      if (ratio(other, ground) > ratio(best, ground)) best = other;
    }
    if (ratio(best, ground) < o.contrast && !warned && window.console) {
      warned = true;
      console.warn('[gk_core_stuff] chart_colors: a graph mark cannot hold the contrast against its ground', css(c), css(ground));
    }
    return css(best);
  }
  // The colour the mark stands on: the first ground behind the graph that is not see-through, else the surface role
  function ground(host) {
    for (var n = host; n && n.nodeType === 1; n = n.parentElement) {
      var c = parseColour(getComputedStyle(n).backgroundColor);
      if (c && c.a > 0) return c;
    }
    return parseColour(color(R.surface));
  }
  var styled = new Set();
  function graphs() {
    var hosts = Array.prototype.slice.call(document.getElementsByClassName(o.graph));
    var gantt = document.getElementById(o.gantt);
    if (gantt) hosts.push(gantt);
    var on = active();
    hosts.forEach(function (host) {
      watch(host);
      var bg = on ? ground(host) : null, any = false;
      Array.prototype.forEach.call(host.querySelectorAll('[stroke], [fill]'), function (el) {
        ['stroke', 'fill'].forEach(function (prop) {
          if (!on) { if (styled.has(el)) el.style[prop] = ''; return; }
          var c = parseColour(drawn(el, prop));
          if (!c || !bg) return;
          var want = holding(c, bg);
          if (want) { el.style[prop] = want; styled.add(el); any = true; } else if (styled.has(el)) el.style[prop] = '';
        });
        if (!on) styled.delete(el);
      });
      if (any) G.mark(host, 'chart_colors'); else G.unmark(host, 'chart_colors');
    });
  }
  // The colour core gave the mark in its attribute, resolved, whatever this script set on its style
  var reader = null;
  function drawn(el, prop) {
    var v = el.getAttribute(prop);
    if (!v || v === 'none' || v.indexOf('url(') === 0) return null;
    if (!reader) {
      reader = document.createElement('span');
      reader.className = 'gk-core-stuff-chart-colors-probe';
      reader.style.display = 'none';
      document.body.appendChild(reader);
    }
    reader.style.color = '';
    reader.style.color = v;
    return reader.style.color ? getComputedStyle(reader).color : null;
  }

  // The Gantt chart's today line, found by the id core gives it. Core draws it as an edge of that element, and reads
  // the progress line's colour from the same element each time it draws that line, so the line core draws from then on
  // follows; one already drawn is a mark in the drawing and is held there by the same rule. Each edge the element
  // draws keeps its hue at a lightness that holds the contrast against its ground. What core's own style said for the
  // edge is kept and put back first on every pass, so the rule always starts from core's colour
  var SIDES = ['top', 'right', 'bottom', 'left'];
  var edges = new WeakMap();
  function todayLine() {
    var el = o.today && document.getElementById(o.today);
    if (!el) return;
    var kept = edges.get(el);
    if (kept) {
      Object.keys(kept).forEach(function (p) {
        if (kept[p].value) el.style.setProperty(p, kept[p].value, kept[p].priority); else el.style.removeProperty(p);
      });
      edges.delete(el);
      G.unmark(el, 'chart_colors');
    }
    if (!active()) return;
    var bg = ground(el), cs = getComputedStyle(el), wants = {};
    if (!bg) return;
    SIDES.forEach(function (side) {
      if (!(parseFloat(cs.getPropertyValue('border-' + side + '-width')) > 0)) return;
      var p = 'border-' + side + '-color', c = parseColour(cs.getPropertyValue(p));
      // an edge that is see-through draws nothing, and is left so
      var want = c && c.a > 0 ? holding(c, bg) : null;
      if (want) wants[p] = want;
    });
    var props = Object.keys(wants);
    if (!props.length) return;
    kept = {};
    props.forEach(function (p) { kept[p] = { value: el.style.getPropertyValue(p), priority: el.style.getPropertyPriority(p) }; });
    props.forEach(function (p) { el.style.setProperty(p, wants[p]); });
    edges.set(el, kept);
    G.mark(el, 'chart_colors');
  }

  // Core draws the graphs again on a resize and on its own options: a new pass then
  var watched = new WeakSet(), pending = false;
  function later() {
    if (pending) return;
    pending = true;
    window.requestAnimationFrame(function () { pending = false; graphs(); });
  }
  function watch(host) {
    if (watched.has(host)) return;
    watched.add(host);
    new MutationObserver(later).observe(host, { childList: true, subtree: true, attributes: true, attributeFilter: ['stroke', 'fill'] });
  }

  function pass() { if (document.body) { charts(); todayLine(); graphs(); } }
  // A page whose mode changes is drawn again: the dark mode's class, or a theme's tone. Once at once and once a frame
  // later, and again when a stylesheet finishes loading, so that roles a newly linked sheet brings are read when they hold
  // (an unchanged signature leaves a chart as it is)
  function modeChanged() { pass(); window.requestAnimationFrame(pass); }
  new MutationObserver(modeChanged).observe(html, { attributes: true, attributeFilter: ['class'].concat(o.tone ? [o.tone] : []) });
  document.addEventListener('load', function (e) {
    var t = e.target;
    if (t instanceof HTMLLinkElement && /(^|\s)stylesheet(\s|$)/i.test(t.rel)) pass();
  }, true);
  G.onContent(pass);
})();
