# frozen_string_literal: true

module GkCoreStuff
  # submit_word: core's word for save on the submit button that saves a form.
  # The upstream form is patch/submit_word-<series>.diff (docs/modules/submit_word.md). Until core has it, the look is hooked
  # in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :submit_word, default: 'off', script: true, options: -> { { from: ::I18n.t(:button_submit), to: ::I18n.t(:button_save) } }
end
