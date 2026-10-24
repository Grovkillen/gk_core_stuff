# frozen_string_literal: true

module GkCoreStuff
  # label_rows: a form row with only text or a link stands on the label's line.
  # The upstream form is patch/label_rows-<series>.diff (docs/modules/label_rows.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :label_rows, default: 'optional', stylesheet: true
end
