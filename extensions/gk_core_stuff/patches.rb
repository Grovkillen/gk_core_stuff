# frozen_string_literal: true

module GkCoreStuff
  # Core patches, all applied from here. Each module is a core candidate of its own and keeps how it hooks in beside
  # its code (modules/<name>/module.rb, the block given to register); a module core already has hooks nothing in
  # (in_core). What each assumes of core is said in its module:
  # * done_ratio_text: ApplicationHelper#progress_bar, QueriesHelper#column_value,
  #   Redmine::FieldFormat::ProgressbarFormat#formatted_value.
  # * single_preference: User#pref.
  # * time_ampm_nbsp: Redmine::I18n#format_time, I18n.localize and I18n.l (only inside format_time), QueriesHelper#csv_value.
  # * avatar_sources: AvatarsHelper#avatar.
  # * settings_tabs: the tabs DSL on Redmine::Plugin, ProjectsHelper#project_settings_tabs,
  #   SettingsHelper#administration_settings_tabs, UsersHelper#user_settings_tabs, GroupsHelper#group_settings_tabs
  #   and IssuesHelper#issue_history_tabs.
  # * journal_details: journal_detail on Redmine::Plugin and IssuesHelper#show_detail.
  # * principal_marks: ApplicationHelper#link_to_principal, and the one link_to it draws.
  # * breadcrumb_marks: ApplicationHelper#page_header_title and the link_to_project calls inside it.
  # * menu_marks: Redmine::MenuManager::MenuHelper#render_menu, #render_single_menu_node and the one link_to it draws.
  # The modules are applied in the order they are required in init.rb. Two prepend ApplicationHelper#link_to
  # (anchor_marks for toggle_link's data, principal_marks for the principal's id) and one the menu helper's link_to
  # (menu_marks for the menu's name); each acts only while its own helper draws and otherwise passes the call on
  # unchanged. The list of
  # core's exports (exports.rb) hooks nothing in: revisions names the exports and records logs them, each with its own
  # patch.
  # Applied directly from init.rb, which Redmine runs inside to_prepare at start and again after every reload in
  # development mode; every prepend is guarded, so a reload never adds a module twice.
  module Patches
    module_function

    def apply!
      GkCoreStuff.apply_modules!
    end
  end
end
