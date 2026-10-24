# frozen_string_literal: true

module GkCoreStuff
  # list_sort: check-box lists core draws in its own order stand in alphabetical order, projects under their parent.
  # The upstream form is patch/list_sort-<series>.diff (docs/modules/list_sort.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :list_sort, default: 'optional', script: true
end
