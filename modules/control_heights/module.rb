# frozen_string_literal: true

module GkCoreStuff
  # control_heights: buttons and fields on one line in the same box get one height.
  # The upstream form is patch/control_heights-<series>.diff (docs/modules/control_heights.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :control_heights, default: 'optional', script: true
end
