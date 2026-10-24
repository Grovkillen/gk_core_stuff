# frozen_string_literal: true

module GkCoreStuff
  # warning_balance: a warning or info box without an icon gets the same margin on both sides.
  # The upstream form is patch/warning_balance-<series>.diff (docs/modules/warning_balance.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :warning_balance, default: 'optional', stylesheet: true
end
