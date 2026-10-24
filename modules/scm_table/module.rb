# frozen_string_literal: true

module GkCoreStuff
  # scm_table: the version control table under Settings, Repositories drawn as core's other lists.
  # The upstream form is patch/scm_table-<series>.diff (docs/modules/scm_table.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :scm_table, default: 'optional', stylesheet: true
end
