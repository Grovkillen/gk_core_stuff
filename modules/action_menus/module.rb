# frozen_string_literal: true

module GkCoreStuff
  # action_menus (step 04 of the proposal view_hooks, redmine/core_proposals/view_hooks/stege/04_action_menus.patch):
  # the _contextual hook on 16 pages, the _actions_menu hook on 8, and menus a plugin adds items to as to core's own
  # menus, for an object: :issue_actions (the issue's actions menu), :issue_context_menu (the issue list's context menu),
  # :project_actions, :user_actions and :version_actions, rendered by render_object_menu_items. Core has neither. The
  # views are core's own with the step's lines, one copy per series, made by core_views.ps1 and chosen by compat, as in
  # layout_hooks; render_object_menu_items and object_menu_item_allowed? are added to MenuManager's helper. A plugin
  # adds an item as to any core menu:
  #   Redmine::MenuManager.map(:issue_actions).push :a_action, { controller: 'a', action: 'do' },
  #     caption: :label_a_action, icon: 'add', if: ->(issue) { issue.closed? }
  # Always on, and it stands aside the day core has the step (compat's action_menus).
  module ActionMenus
    MENUS = %i[issue_actions issue_context_menu project_actions user_actions version_actions].freeze
    HOOKS = %i[view_boards_show_contextual view_documents_index_contextual view_documents_show_contextual
               view_groups_show_contextual view_issues_index_contextual view_issues_show_contextual
               view_messages_show_contextual view_news_index_contextual view_news_show_contextual
               view_projects_index_contextual view_projects_show_contextual view_timelog_index_contextual
               view_users_index_contextual view_users_show_contextual view_versions_index_contextual
               view_wiki_show_contextual view_issues_index_actions_menu view_issues_show_actions_menu
               view_projects_show_actions_menu view_repositories_navigation_actions_menu
               view_timelog_index_actions_menu view_users_index_actions_menu view_versions_index_actions_menu
               view_wiki_show_actions_menu].freeze

    def self.views_dir = GkCoreStuff.series_views(:action_menus)

    # The items plugins added to the object menus, by menu (for the settings page)
    def self.items = MENUS.to_h { |m| [m, ::Redmine::MenuManager.items(m).root.children.map(&:name)] }

    # As the proposal's Redmine::MenuManager::MenuHelper#render_object_menu_items and #object_menu_item_allowed?
    module MenuHelperPatch
      def render_object_menu_items(menu, object, project = nil, list: false)
        links = []
        ::Redmine::MenuManager.items(menu).root.children.each do |item|
          next unless object_menu_item_allowed?(item, object, project)

          url =
            case item.url
            when Proc then item.url.call(object)
            when Hash
              # a list of objects is an Array or a relation (the selected issues)
              many = object.respond_to?(:to_ary)
              key = many ? :ids : item.param
              value = many ? object.to_ary.map(&:id).sort : object
              { key => value }.merge(item.url)
            when Symbol then send(item.url, object)
            else item.url
            end
          caption = item.caption(object)
          label = item.icon.present? ? sprite_icon(item.icon, h(caption), plugin: item.plugin) : h(caption)
          link = link_to(label, use_absolute_controller(url), item.html_options)
          links << (list ? content_tag('li', link) : link)
        end
        safe_join(links)
      end

      def object_menu_item_allowed?(item, object, project)
        return false if project && item.permission && !::User.current.allowed_to?(item.permission, project)
        return false if item.condition && !item.condition.call(object)

        true
      end
    end
  end

  # Always on, without a setting: the hooks and menus are for other plugins and change nothing until one adds to them
  register :action_menus, issue: 44660, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:action_menus) }, always: true do
    unless ::Redmine::MenuManager::MenuHelper < ActionMenus::MenuHelperPatch
      ::Redmine::MenuManager::MenuHelper.prepend(ActionMenus::MenuHelperPatch)
    end
    GkCoreStuff.prepend_series_views(:action_menus)
  end
end
