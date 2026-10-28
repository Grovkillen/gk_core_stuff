# frozen_string_literal: true

module GkCoreStuff
  # list_hooks (step 06 of the proposal view_hooks, redmine/core_proposals/view_hooks/stege/06_list_hooks.patch): in the
  # lists of issues, projects and users a plugin adds CSS classes to a row (view_<list>_list_row_css_classes, through
  # css_classes_from_hook) and content after it (view_<list>_list_row_after, with the colspan). Core has neither. The
  # views are core's own with the step's lines, one copy per series, made by core_views.ps1 and chosen by compat, as in
  # layout_hooks; the helper css_classes_from_hook is added to ApplicationHelper. Always on, and it stands aside the day
  # core has the step (compat's list_hooks).
  module ListHooks
    HOOKS = %i[view_issues_list_row_css_classes view_issues_list_row_after view_projects_list_row_css_classes
               view_projects_list_row_after view_users_list_row_css_classes view_users_list_row_after].freeze

    def self.views_dir = GkCoreStuff.series_views(:list_hooks)

    module ApplicationHelperPatch
      # The CSS classes that plugins add to an element through +hook+, as a plain (not html_safe) String so that it is
      # escaped in the attribute (as the proposal)
      def css_classes_from_hook(hook, context = {})
        String.new(call_hook(hook, context)).split.join(' ')
      end
    end
  end

  # Always on, without a setting: the hooks are for other plugins and change nothing until one listens
  register :list_hooks, issue: 44660, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:list_hooks) }, always: true do
    ::ApplicationHelper.prepend(ListHooks::ApplicationHelperPatch) unless ::ApplicationHelper < ListHooks::ApplicationHelperPatch
    GkCoreStuff.prepend_series_views(:list_hooks)
  end
end
