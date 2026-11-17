# frozen_string_literal: true
# Small fixes in Redmine's own behaviour, one switchable module each, written as core candidates: the upstream part is
# a diff per series in modules/<name>/patch, the module here is how we hook it in until core has it.
# First module: done_ratio_text (redmine.org #5284).
# Depends on: gk_gui_stuff and gk_compat required, each at the lowest version the gate names or later (gate.rb;
# compat: the running series' folders, whether core has what a module adds); optional gk_records (the levels of the
# looks, kept as appearance settings), gk_scenarios. Without gk_gui_stuff or gk_compat, with an older base version of
# either, or with a gk_gui_stuff whose own gate is closed, the interface of core_stuff is closed (GkCoreStuff.open?,
# gate.rb): no module hooks in but the pass over formatted text, no look, no hook answers, nothing registered
# elsewhere; the settings page says why, and the migrations run all the same. What protects or leaves a trace holds
# whatever the gate says: the filter of values in the log, the list of core's exports and the pass over formatted text.

require_relative 'extensions/gk_core_stuff/core'
# The gate to GK GUI Stuff and GK Compat, before the files that ask it
require_relative 'extensions/gk_core_stuff/gate'
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
   list_align field_widths settings_widths control_heights submit_word ajax_indicator native_texts list_sort menu_icons external_links
   chart_colors dark_mode].each { |m| require_relative "modules/#{m}/module" }
require_relative 'extensions/gk_core_stuff/hooks'
require_relative 'extensions/gk_core_stuff/patches'

Redmine::Plugin.register :gk_core_stuff do
  name        'GK Core Stuff'
  author      'Jimmy Westberg'
  description "Small fixes and additions to Redmine's own behaviour, one switchable module each, written as patches to Redmine"
  version     '1.05.000'
  requires_redmine version_or_higher: '6.0.0'

  settings default: GkCoreStuff.defaults, partial: 'settings/gk_core_stuff_settings'
end

# core_stuff at work starts at the end of each preparation, once every plugin's init.rb has run (GkCoreStuff::Gate::Boot,
# core's hook after_plugins_loaded), again after every reload: always the log filter and the pass over formatted text
# (Patches.protect!); with GK GUI Stuff and GK Compat also the DSL's names and every core patch
# (extensions/gk_core_stuff/patches.rb, each module guarded against a second prepend). Without GK GUI Stuff or GK
# Compat only the first two, and the view listener answers no hook (Gate::Listener).
Redmine::Hook.add_listener(GkCoreStuff::Gate::Boot) unless Redmine::Hook.listeners.any?(GkCoreStuff::Gate::Boot)
Redmine::Hook.add_listener(GkCoreStuff::Hooks) unless Redmine::Hook.listeners.any?(GkCoreStuff::Hooks)
# Everything below runs once every plugin is in, and only with GK GUI Stuff and GK Compat (GkCoreStuff.open?, gate.rb)
# Which of the hook modules' views a plugin overrides: known only when every plugin has registered its views
Rails.configuration.after_initialize { GkCoreStuff.log_shadowed_views! if GkCoreStuff.open? }
# From then on GkCoreStuff.hook? keeps its answers (which page calls which hook is known only then)
Rails.configuration.after_initialize { GkCoreStuff.settle_views! if GkCoreStuff.open? }
# The looks and the three modules that change how core's pages read are appearance settings in records' register
# (records loads after core_stuff); every one off in a new installation, and off without records. Each row comes with
# its values (the places of the external links look among them), so a reload, which runs this again, declares them
# again with the row
Rails.configuration.after_initialize { GkCoreStuff::Looks.declare_appearances! if GkCoreStuff.open? }
# registrations.yml read through records' one reader: a label the file names that no locale has, and an appearance
# setting the code registers that the file does not list, are written to the log at start
Rails.configuration.after_initialize { ::GkRecords::Registrations.check!(:gk_core_stuff) if GkCoreStuff.open? && defined?(::GkRecords::Registrations) }
