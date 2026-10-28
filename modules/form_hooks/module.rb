# frozen_string_literal: true

module GkCoreStuff
  # form_hooks (step 05 of the proposal view_hooks, redmine/core_proposals/view_hooks/stege/05_form_hooks.patch): hooks
  # at the top and bottom of seven forms (groups, issues and their custom fields, projects, trackers, users, versions)
  # and after the issue's subject, description and attributes, the user's authentication and mail notifications. Core
  # calls none of them, so a plugin that adds a field to a form overrides the whole view. The views are core's own
  # with the step's lines, one copy per series, made by core_views.ps1 and chosen by compat, as in layout_hooks. Only
  # views; always on, and it stands aside the day core has the step (compat's form_hooks).
  module FormHooks
    HOOKS = %i[view_groups_form_top view_groups_form_bottom view_issues_form_after_subject
               view_issues_form_after_description view_issues_form_after_attributes view_issues_form_custom_fields_top
               view_issues_form_custom_fields_bottom view_projects_form_top view_projects_form_bottom
               view_trackers_form_top view_trackers_form_bottom view_users_form_top view_users_form_after_authentication
               view_users_form_after_mail_notifications view_users_form_bottom view_versions_form_top
               view_versions_form_bottom].freeze

    def self.views_dir = GkCoreStuff.series_views(:form_hooks)
  end

  # Always on, without a setting: the hooks are for other plugins and change nothing until one listens
  register :form_hooks, issue: 44660, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:form_hooks) }, always: true do
    GkCoreStuff.prepend_series_views(:form_hooks)
  end
end
