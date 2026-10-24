# frozen_string_literal: true

module GkCoreStuff
  # field_widths: lists and text fields straight under each other in a form get one width.
  # The upstream form is patch/field_widths-<series>.diff (docs/modules/field_widths.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :field_widths, default: 'optional', script: 'gk_core_stuff_field_widths'
end
