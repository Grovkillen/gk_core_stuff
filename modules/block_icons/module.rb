# frozen_string_literal: true

module GkCoreStuff
  # block_icons: the move handle gets the colour of the icons beside it; the two groups of icons on a My page block get core's gap.
  # The upstream form is patch/block_icons-<series>.diff (docs/modules/block_icons.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :block_icons, default: 'optional', stylesheet: true
end
