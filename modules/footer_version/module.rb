# frozen_string_literal: true

module GkCoreStuff
  # footer_version: Redmine's version after "Powered by Redmine" in the footer, for everyone who sees a page (also one
  # not signed in). Off from the start. Only Redmine's own version; the plugins' versions are not shown.
  # The upstream form is patch/footer_version-<series>.diff: a setting footer_show_version on Administration >
  # Settings > Display (off by default) and the version in layouts/base.html.erb. Core's layout is not overridden
  # here: the version is drawn on the server on the hook view_layouts_base_footer_powered_by_after, which core calls
  # right after the link to Redmine (more_view_hooks, step 10 of view_hooks, adds it until core has it). Where the
  # hook is not called (more_view_hooks off, a plugin's own layouts/base first, a series without copies) no version
  # is shown; the link is never searched for in the page. The browser's footer only, never PDFs or exports.
  module FooterVersion
    HOOK = :view_layouts_base_footer_powered_by_after

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
        o ? o == '1' : GkCoreStuff.appearance_on?(:footer_version)
      end

      # 7.0.2, without the branch (stable, devel) that Administration > Information shows
      def version = [::Redmine::VERSION::MAJOR, ::Redmine::VERSION::MINOR, ::Redmine::VERSION::TINY].join('.')

      # What the hook draws right after the link: a space and the version, or nothing with the module off
      def footer_text
        return ''.html_safe unless on?

        ERB::Util.html_escape(" #{version}")
      end
    end
  end

  # in_core: core has the setting (the patch is in); off from the start, the administrator sets its appearance setting
  register :footer_version, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:footer_version_setting) } do
    # nothing to prepend: the footer hook (hooks.rb) asks FooterVersion.footer_text
  end
end
