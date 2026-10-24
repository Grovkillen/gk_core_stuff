# frozen_string_literal: true

module GkCoreStuff
  # footer_version: Redmine's version after "Powered by Redmine" in the footer, for everyone who sees a page (also one
  # not signed in). Off from the start. Only Redmine's own version; the plugins' versions are not shown.
  # The upstream form is patch/footer_version-<series>.diff: a setting footer_show_version on Administration >
  # Settings > Display (off by default) and the version in layouts/base.html.erb. Core's layout is not overridden
  # here: the head hook gives the version in a meta tag and a small script puts it after the link in #footer. Without
  # JavaScript the footer is core's own. The browser's footer only, never PDFs or exports.
  module FooterVersion
    class << self
      # A scenario can ask for the module on or off for a block without touching the instance's settings
      def with(on)
        old = Thread.current[:gk_core_stuff_fv]
        Thread.current[:gk_core_stuff_fv] = on ? '1' : '0'
        yield
      ensure
        Thread.current[:gk_core_stuff_fv] = old
      end

      def on?
        o = Thread.current[:gk_core_stuff_fv]
        o ? o == '1' : GkCoreStuff.on?(:footer_version)
      end

      # 7.0.2, without the branch (stable, devel) that Administration > Information shows
      def version = [::Redmine::VERSION::MAJOR, ::Redmine::VERSION::MINOR, ::Redmine::VERSION::TINY].join('.')

      # The head tags for a page: the meta tag and the script, or nothing with the module off
      def head_tags(view)
        return ''.html_safe unless on?

        view.content_tag(:meta, nil, id: 'gk-core-stuff-footer-version', name: 'gk-core-stuff-footer-version', 'data-version': version) +
          view.javascript_include_tag('gk_core_stuff_footer_version', plugin: 'gk_core_stuff', defer: true)
      end
    end
  end

  # in_core: core has the setting (the patch is in)
  register :footer_version, issue: nil, defaults: { 'footer_version' => '0' }, in_core: -> { ::Setting.respond_to?(:footer_show_version?) } do
    # nothing to prepend: the head hook (hooks.rb) asks FooterVersion.head_tags
  end
end
