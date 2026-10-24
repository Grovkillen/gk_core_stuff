# frozen_string_literal: true

module GkCoreStuff
  # sidebar_spacing: a plugin's block in the sidebar gets core's 14 px above it.
  # The upstream form is patch/sidebar_spacing-<series>.diff (docs/modules/sidebar_spacing.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :sidebar_spacing, default: 'optional', stylesheet: true
end
