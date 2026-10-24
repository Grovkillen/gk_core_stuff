# frozen_string_literal: true

module GkCoreStuff
  # settings_widths: the lists and text fields in a box of core's settings get one width.
  # The upstream form is patch/settings_widths-<series>.diff (docs/modules/settings_widths.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :settings_widths, default: 'optional', script: 'gk_core_stuff_field_widths'
end
