# frozen_string_literal: true

module GkCoreStuff
  # Core patches, all applied from here. Each module is a core candidate of its own and keeps how it hooks in beside
  # its code (modules/<name>/module.rb, the block given to register); a module core already has hooks nothing in
  # (in_core). What each assumes of core is said in its module:
  # * done_ratio_text: ApplicationHelper#progress_bar, QueriesHelper#column_value,
  #   Redmine::FieldFormat::ProgressbarFormat#formatted_value.
  # * single_preference: User#pref.
  # * time_ampm_nbsp: Redmine::I18n#format_time, QueriesHelper#csv_value.
  # * avatar_sources: AvatarsHelper#avatar.
  # * settings_tabs: the tabs DSL on Redmine::Plugin, ProjectsHelper#project_settings_tabs,
  #   SettingsHelper#administration_settings_tabs, UsersHelper#user_settings_tabs, GroupsHelper#group_settings_tabs
  #   and IssuesHelper#issue_history_tabs.
  # * journal_details: journal_detail on Redmine::Plugin and IssuesHelper#show_detail.
  # * Looks (extensions/gk_core_stuff/looks.rb): UserPreference#gk_core_stuff_looks and its safe attribute.
  # The modules are applied in the order they are required in init.rb; no two prepend the same method. The list of
  # core's exports (exports.rb) hooks nothing in: revisions names the exports and records logs them, each with its own
  # patch.
  # Applied directly from init.rb, which Redmine runs inside to_prepare at start and again after every reload in
  # development mode; every prepend is guarded, so a reload never adds a module twice.
  module Patches
    module_function

    def apply!
      GkCoreStuff.apply_modules!
      Looks.apply!
    end
  end
end
