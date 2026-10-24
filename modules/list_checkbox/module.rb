# frozen_string_literal: true

module GkCoreStuff
  # list_checkbox: the row's check box in a list stands in the middle of the row.
  # The upstream form is patch/list_checkbox-<series>.diff (docs/modules/list_checkbox.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :list_checkbox, default: 'optional', stylesheet: true
end
