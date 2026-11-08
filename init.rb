# frozen_string_literal: true
# Small fixes in Redmine's own behaviour, one switchable module each, written as core candidates: the upstream part is
# a diff per series in modules/<name>/patch, the module here is how we hook it in until core has it.
# First module: done_ratio_text (redmine.org #5284).
# Depends on: none required; optional gk_compat (whether core has what a module adds), gk_records (the levels of the
# looks, kept as appearance settings), gk_scenarios.

# Values that never belong in the log (people's PIN codes, one-time tokens, a person's identifier such as a personal
# identity number): filtered from every request's parameters, as Redmine filters passwords. The patterns are anchored,
# so a project's identifier or an authenticity_token stays as it is.
Rails.application.config.filter_parameters.concat([/\A(pin|pin_again|new_pin|new_pin_again)\z/, /\Atoken\z/, 'identifier.value'])

require_relative 'extensions/gk_core_stuff/core'
require_relative 'extensions/gk_core_stuff/looks'
# which of core's actions send an export, for the plugins that name and log them (revisions, records)
require_relative 'extensions/gk_core_stuff/exports'
require_relative 'modules/done_ratio_text/module'
require_relative 'modules/single_preference/module'
require_relative 'modules/time_ampm_nbsp/module'
require_relative 'modules/avatar_sources/module'
require_relative 'modules/footer_version/module'
require_relative 'modules/minimagick_path/module'
require_relative 'modules/settings_tabs/module'
require_relative 'modules/journal_details/module'
require_relative 'modules/layout_hooks/module'
require_relative 'modules/action_menus/module'
require_relative 'modules/form_hooks/module'
require_relative 'modules/list_hooks/module'
require_relative 'modules/section_marks/module'
# marks on parts of core's pages (step 09) and more hooks in core's views (step 10), built on the earlier steps' copies
require_relative 'modules/anchor_marks/module'
require_relative 'modules/more_view_hooks/module'
# one pass over the links and runs of text of every formatted text, which other plugins hook their marks into
require_relative 'modules/formatting_processors/module'
# marks on the counts of core's issue reports, so that a plugin knows a column by its mark
require_relative 'modules/report_marks/module'
# the principal's id on core's links to a user or group, and the project on the header's breadcrumb links
require_relative 'modules/principal_marks/module'
require_relative 'modules/breadcrumb_marks/module'
# the menu's name on every link core draws in a menu, so that a plugin knows the account menu's links from the mark
require_relative 'modules/menu_marks/module'
# The looks: fixes of how core's own pages look or read (Looks)
%w[list_badge list_hash heading_badge list_checkbox sidebar_spacing label_rows scm_table warning_balance block_icons
   list_align field_widths settings_widths control_heights submit_word ajax_indicator native_texts list_sort menu_icons external_links].each { |m| require_relative "modules/#{m}/module" }
require_relative 'extensions/gk_core_stuff/hooks'
require_relative 'extensions/gk_core_stuff/patches'

Redmine::Plugin.register :gk_core_stuff do
  name        'GK Core Stuff'
  author      'Jimmy Westberg'
  description "Small fixes and additions to Redmine's own behaviour, one switchable module each, written as patches to Redmine"
  version     '1.04.000'
  requires_redmine version_or_higher: '6.0.0'

  settings default: GkCoreStuff.defaults, partial: 'settings/gk_core_stuff_settings'
end

# The core patches (extensions/gk_core_stuff/patches.rb), applied here and again on every reload
GkCoreStuff::Patches.apply!
Redmine::Hook.add_listener(GkCoreStuff::Hooks) unless Redmine::Hook.listeners.any?(GkCoreStuff::Hooks)
# Which of the hook modules' views a plugin overrides: known only when every plugin has registered its views
Rails.configuration.after_initialize { GkCoreStuff.log_shadowed_views! }
# From then on GkCoreStuff.hook? keeps its answers (which page calls which hook is known only then)
Rails.configuration.after_initialize { GkCoreStuff.settle_views! }
# The looks and the three modules that change how core's pages read are appearance settings in records' register
# (records loads after core_stuff); every one off in a new installation, and off without records. Each row comes with
# its values (the places of the external links look among them), so a reload, which runs this again, declares them
# again with the row
Rails.configuration.after_initialize { GkCoreStuff::Looks.declare_appearances! }
# registrations.yml read through records' one reader: a label the file names that no locale has, and an appearance
# setting the code registers that the file does not list, are written to the log at start
Rails.configuration.after_initialize { ::GkRecords::Registrations.check!(:gk_core_stuff) if defined?(::GkRecords::Registrations) }
