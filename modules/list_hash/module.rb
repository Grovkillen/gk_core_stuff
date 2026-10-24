# frozen_string_literal: true

module GkCoreStuff
  # list_hash: the number in issue lists written with its #, as everywhere else.
  # The upstream form is patch/list_hash-<series>.diff (docs/modules/list_hash.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :list_hash, default: 'off', stylesheet: true
end
