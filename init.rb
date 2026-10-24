# frozen_string_literal: true
# Revision: 0.00.001
# Small fixes in Redmine's own behaviour, one switchable module each, written as core candidates: the upstream part is
# a diff per series in modules/<name>/patch, the module here is how we hook it in until core has it.
# First module: done_ratio_text (redmine.org #5284).
# Depends on: none required; optional gk_revisions, gk_records, gk_scenarios.

# Values that never belong in the log (people's PIN codes, one-time tokens, a person's identifier such as a personal
# identity number): filtered from every request's parameters, as Redmine filters passwords. The patterns are anchored,
# so a project's identifier or an authenticity_token stays as it is.
Rails.application.config.filter_parameters.concat([/\A(pin|pin_again|new_pin|new_pin_again)\z/, /\Atoken\z/, 'identifier.value'])

require_relative 'extensions/gk_core_stuff/core'
require_relative 'extensions/gk_core_stuff/looks'
require_relative 'modules/done_ratio_text/module'
require_relative 'modules/export_names/module'
require_relative 'modules/export_log/module'
require_relative 'modules/single_preference/module'
require_relative 'modules/time_ampm_nbsp/module'
require_relative 'modules/avatar_sources/module'
require_relative 'modules/footer_version/module'
require_relative 'modules/minimagick_path/module'
require_relative 'modules/view_registries/module'
# The looks: fixes of how core's own pages look or read, moved here from gui_stuff 2026-10-22 (Looks)
%w[list_badge list_hash heading_badge list_checkbox sidebar_spacing label_rows scm_table warning_balance block_icons
   list_align field_widths settings_widths control_heights submit_word ajax_indicator native_texts list_sort].each { |m| require_relative "modules/#{m}/module" }
require_relative 'extensions/gk_core_stuff/hooks'

Redmine::Plugin.register :gk_core_stuff do
  name        'GK Core Stuff'
  author      'Jimmy Westberg'
  description "Small fixes and additions to Redmine's own behaviour, one switchable module each, written as patches to core"
  version     '1.00.000'
  requires_redmine version_or_higher: '6.0.0'

  settings default: GkCoreStuff.defaults, partial: 'settings/gk_core_stuff_settings'

  # export_log: who may see the exports, downloads and prints in a project (the events in records ask it)
  permission :gk_core_stuff_view_exports, {}, require: :member
end

GkCoreStuff.apply_modules!
GkCoreStuff::Looks.apply!
# core's exports declared in revisions' one rule for names (revisions loads after core_stuff)
Rails.configuration.after_initialize { GkCoreStuff::ExportNames.declare! }
# the export log's targets and event kinds in records (records loads after core_stuff)
Rails.configuration.after_initialize { GkCoreStuff::ExportLog.register_records! }
Redmine::Hook.add_listener(GkCoreStuff::Hooks) unless Redmine::Hook.listeners.any?(GkCoreStuff::Hooks)
