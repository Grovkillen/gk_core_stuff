# frozen_string_literal: true

module GkCoreStuff
  # The modules' CSS: the same rules the upstream diff adds to core's application.css
  class Hooks < Redmine::Hook::ViewListener
    include GkCoreStuff::Gate::Listener # silent without GK GUI Stuff or GK Compat (gate.rb)

    def view_layouts_base_html_head(context = {})
      out = stylesheet_link_tag('gk_core_stuff', plugin: 'gk_core_stuff')
      # dark_mode, while it is on for this person: its sheets and the script that sets the class from the device; the
      # late sheet in the page's own header_tags (context[:hook_caller]), after core's per-page sheets
      out += GkCoreStuff::DarkMode.head_tag(self, User.current, context[:hook_caller])
      # the looks that are on for this person: their stylesheets and scripts
      out += GkCoreStuff::Looks.head_tags(self)
      out
    end

    # footer_version: for everyone, also one not signed in; drawn only where core (or more_view_hooks) calls the hook
    def view_layouts_base_footer_powered_by_after(_context = {})
      GkCoreStuff::FooterVersion.footer_text
    end
  end
end
