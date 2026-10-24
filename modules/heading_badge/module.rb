# frozen_string_literal: true

module GkCoreStuff
  # heading_badge: the badges after a page's heading stand in the middle of the heading's capitals.
  # The upstream form is patch/heading_badge-<series>.diff (docs/modules/heading_badge.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :heading_badge, default: 'optional', stylesheet: true
end
