# frozen_string_literal: true

module GkCoreStuff
  # more_view_hooks (step 10 of the proposal view_hooks, redmine/core_proposals/view_hooks/stege/10_more_view_hooks.patch):
  # hooks where plugins draw something next to a part of core's pages that has none, so that they draw it on the
  # server in its place instead of moving it there with JavaScript:
  #   view_layouts_base_footer_powered_by_after  in the footer, right after the link to Redmine (layouts/base)
  #   view_issues_show_author_after               on the issue page, right after the author line (:issue)
  #   view_documents_show_details_bottom          on a document's page, under its category, date and custom fields
  #                                               (:document)
  #   view_settings_form_save_after               right after the Save button of every settings form: each tab of
  #                                               Administration > Settings (:tab, the tab's name in trunk) and a
  #                                               plugin's settings (:plugin). :tab is the same in every series: the
  #                                               API tab gives 'integrations' also in 6.0 and 6.1, where core names
  #                                               that tab 'api' (params[:tab] and administration_settings_tabs)
  #   view_my_account_information_after           on My account, right after the Information box (:user, :form)
  #   view_issues_index_list_before               on the issue list page, before the list or the no-data line (:query,
  #                                               :issues)
  #   view_issues_list_before                     at the top of every issue list (issues/_list): the issue list page
  #                                               and the issue blocks of My page (:query, :issues)
  # view_issues_list_before is called only where a list is drawn, so only when there are issues;
  # view_issues_index_list_before is the issue list page's own place, also above the no-data line.
  # Core calls none of them. The views are core's own with the step's lines added, one copy per series in
  # views/<series>/, made by pipeline/scripts/development/core_views.ps1 (never by hand; SOURCE.yml says from which zip
  # and patches). Views that earlier steps also change are built on their lines (layouts/base on 01's and 09's,
  # issues/show on 01's, 08's and 09's, documents/show and issues/index on 04's, issues/_list on 06's, the settings forms
  # on 09's), so the folder stands before theirs. The hooks change nothing until a plugin listens to them, so the module is always on;
  # it stands aside the day core has the step (compat's more_view_hooks).
  module MoreViewHooks
    # The hooks the step adds (listed on the settings page with the ones some plugin listens to)
    HOOKS = %i[view_layouts_base_footer_powered_by_after view_issues_show_author_after view_documents_show_details_bottom
               view_settings_form_save_after view_my_account_information_after view_issues_index_list_before
               view_issues_list_before].freeze
    # The views that call each hook (GkCoreStuff.hook?); the settings hook in every tab the series has a copy of
    # (the API tab is settings/_api in the series) and in a plugin's settings
    HOOK_VIEWS = {
      view_layouts_base_footer_powered_by_after: %w[layouts/base], view_issues_show_author_after: %w[issues/show],
      view_documents_show_details_bottom: %w[documents/show],
      view_settings_form_save_after: %w[settings/_general settings/_display settings/_authentication settings/_api
                                        settings/_projects settings/_users settings/_issues settings/_timelog
                                        settings/_attachments settings/_notifications settings/_mail_handler
                                        settings/_repositories settings/plugin],
      view_my_account_information_after: %w[my/account], view_issues_index_list_before: %w[issues/index],
      view_issues_list_before: %w[issues/_list]
    }.freeze

    def self.views_dir = GkCoreStuff.series_views(:more_view_hooks)
  end

  # Always on, without a setting: the hooks are for other plugins and change nothing until one listens
  register :more_view_hooks, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:more_view_hooks) }, always: true,
                             hooks: MoreViewHooks::HOOK_VIEWS do
    GkCoreStuff.prepend_series_views(:more_view_hooks, replaces: %i[layout_hooks action_menus list_hooks section_marks
                                                                                 anchor_marks])
  end
end
