# frozen_string_literal: true

module GkCoreStuff
  # menu_marks: the menu's name on every link core draws in a menu with render_menu, data-menu (top_menu, account_menu,
  # application_menu, project_menu, admin_menu), so that a plugin knows which menu a link stands in from the mark and
  # never from where the link sits (the account menu's links inside the profile dropdown, a list inside a list).
  # Core draws a menu's links in Redmine::MenuManager::MenuHelper#render_single_menu_node, one link_to per item, while
  # render_menu draws the menu; the mark is handed to that one link_to with core's own attributes. A child menu's links
  # (render_menu_node_with_children) are drawn the same way and carry the same mark; its loose children (child_menus)
  # are drawn by render_unattached_menu_item with a link_to of their own, which gets the mark the same way. The link's
  # address, class and text stay core's, and nothing shows. A prepend on core's helper, no copied views.
  # Always on; it stands aside the day core has the mark (compat's menu_marks).
  module MenuMarks
    ATTRIBUTE = 'data-menu'

    # The attributes of a menu's link: core's, with the menu's name
    def self.link_options(html_options, menu)
      (html_options || {}).merge(ATTRIBUTE => menu.to_s)
    end

    # Prepended on Redmine::MenuManager::MenuHelper
    module MenuHelperPatch
      def render_menu(menu, project = nil)
        return super unless GkCoreStuff.on?(:menu_marks)

        outer = @gk_core_stuff_menu
        @gk_core_stuff_menu = menu.to_s
        super
      ensure
        @gk_core_stuff_menu = outer
      end

      def render_single_menu_node(item, caption, url, selected)
        return super unless @gk_core_stuff_menu

        @gk_core_stuff_menu_link = @gk_core_stuff_menu
        super
      ensure
        @gk_core_stuff_menu_link = nil
      end

      # a child menu's loose children (child_menus): core draws each with its own link_to outside
      # render_single_menu_node, so the mark is handed to that link_to in the same way
      def render_unattached_menu_item(menu_item, project)
        return super unless @gk_core_stuff_menu

        @gk_core_stuff_menu_link = @gk_core_stuff_menu
        super
      ensure
        @gk_core_stuff_menu_link = nil
      end

      def link_to(name = nil, options = nil, html_options = nil, &block)
        menu = @gk_core_stuff_menu_link
        return super if menu.nil? || block || !(html_options.nil? || html_options.is_a?(Hash))

        @gk_core_stuff_menu_link = nil
        super(name, options, MenuMarks.link_options(html_options, menu))
      end
    end
  end

  # Always on, without a setting: the mark is for other plugins and changes nothing that shows
  register :menu_marks, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:menu_marks) }, always: true do
    ::Redmine::MenuManager::MenuHelper.prepend(MenuMarks::MenuHelperPatch) unless ::Redmine::MenuManager::MenuHelper < MenuMarks::MenuHelperPatch
  end
end
