# frozen_string_literal: true

module GkCoreStuff
  # native_texts: the browser's own texts (a field's message, a file field's button) in the page's language.
  # The upstream form is patch/native_texts-<series>.diff (docs/modules/native_texts.md). Until core has it, the look is
  # hooked in from the page's head (Looks, extensions/gk_core_stuff/looks.rb), moved here from gui_stuff 2026-10-22.
  Looks.register :native_texts, default: 'optional', stylesheet: true, script: true,
                                texts: %i[gk_core_stuff_nt_required gk_core_stuff_nt_choose gk_core_stuff_nt_check gk_core_stuff_nt_email
                                          gk_core_stuff_nt_url gk_core_stuff_nt_format gk_core_stuff_nt_short gk_core_stuff_nt_long
                                          gk_core_stuff_nt_min gk_core_stuff_nt_max gk_core_stuff_nt_file_choose gk_core_stuff_nt_files_choose
                                          gk_core_stuff_nt_file_none gk_core_stuff_nt_files_n]
end
