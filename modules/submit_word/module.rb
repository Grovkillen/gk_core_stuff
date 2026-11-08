# frozen_string_literal: true

module GkCoreStuff
  # submit_word: core's word for save on the submit button that saves a form.
  # The upstream form is patch/submit_word-<series>.diff (docs/modules/submit_word.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22. The script
  # finds the buttons by core's form ids and the commit name, never by the button's word, so only core's word for save is
  # passed on. A bulk edit form in copy or move mode (core's follow button or copy field) is left alone.
  Looks.register :submit_word, script: true, options: -> { { to: ::I18n.t(:button_save) } }
end
