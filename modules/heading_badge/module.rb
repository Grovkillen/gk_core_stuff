# frozen_string_literal: true

module GkCoreStuff
  # heading_badge: the badges after a page's heading stand in the middle of the heading's capitals.
  # The upstream form is patch/heading_badge-<series>.diff (docs/modules/heading_badge.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22. The script
  # only sets the effect mark on the badges the stylesheet moves; the classes it finds them by are not stable anchors of
  # a footprint.
  Looks.register :heading_badge, stylesheet: true, script: true
end
