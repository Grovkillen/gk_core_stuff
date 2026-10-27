# frozen_string_literal: true

module GkCoreStuff
  # The modules' CSS: the same rules the upstream diff adds to core's application.css
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(_context = {})
      out = stylesheet_link_tag('gk_core_stuff', plugin: 'gk_core_stuff')
      # footer_version: for everyone, also one not signed in
      out += GkCoreStuff::FooterVersion.head_tags(self)
      # the looks that are on for this person: their stylesheets and scripts
      out += GkCoreStuff::Looks.head_tags(self)
      out
    end

    # The looks a person may switch off (level optional), in core's Preferences box on My account; saved with the
    # account's own Save as the preference gk_core_stuff_looks
    def view_my_account_preferences(context = {})
      looks = GkCoreStuff::Looks.optional
      return '' if looks.empty?

      context[:hook_caller].send(:render, partial: 'my/gk_core_stuff_looks', locals: { looks: looks, pref: context[:user].pref })
    end
  end
end
