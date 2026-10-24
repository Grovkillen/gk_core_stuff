# frozen_string_literal: true

module GkCoreStuff
  # list_badge: a badge in a list's cell stands in the middle of the row instead of core's 4 px lift.
  # The upstream form is patch/list_badge-<series>.diff (docs/modules/list_badge.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :list_badge, default: 'optional', stylesheet: true
end
