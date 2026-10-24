# frozen_string_literal: true

module GkCoreStuff
  # list_align: a list's heading set as its column's cells when they all stand at the start or the end.
  # The upstream form is patch/list_align-<series>.diff (docs/modules/list_align.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :list_align, default: 'optional', script: true
end
