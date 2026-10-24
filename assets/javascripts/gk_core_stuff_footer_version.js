// footer_version: Redmine's version after the link in core's footer ("Powered by Redmine 7.0.2 © ..."), read from the
// meta tag the head hook gives when the module is on. Core's footer is not changed otherwise. No jQuery.
(function () {
  'use strict';
  function put() {
    var meta = document.getElementById('gk-core-stuff-footer-version');
    var link = document.querySelector('#footer a');
    if (!meta || !link || link.getAttribute('data-gk-version')) return;
    link.setAttribute('data-gk-version', '1');
    link.parentNode.insertBefore(document.createTextNode(' ' + meta.getAttribute('data-version')), link.nextSibling);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', put); else put();
})();
