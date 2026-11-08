# frozen_string_literal: true

module GkCoreStuff
  # The modules' CSS: the same rules the upstream diff adds to core's application.css
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(_context = {})
      out = stylesheet_link_tag('gk_core_stuff', plugin: 'gk_core_stuff')
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
