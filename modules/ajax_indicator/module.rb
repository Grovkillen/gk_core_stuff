# frozen_string_literal: true

module GkCoreStuff
  # ajax_indicator: core's Loading box over the marked rows when the request came from a list.
  # The upstream form is patch/ajax_indicator-<series>.diff (docs/modules/ajax_indicator.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :ajax_indicator, default: 'off', script: true
end
