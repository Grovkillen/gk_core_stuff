# frozen_string_literal: true

module GkCoreStuff
  # menu_icons: in a menu (a button row's ..., the journal's ..., the issue list's right click) the icon of the row under
  # the pointer keeps the row's colour, as the row's text does, instead of turning red as the icon of a link does.
  # The upstream form is patch/menu_icons-<series>.diff (docs/modules/menu_icons.md); 6.0 colours an icon as its text
  # and needs none. Until core has it, the look is hooked in from the page's head (Looks, extensions/gk_core_stuff/looks.rb).
  Looks.register :menu_icons, default: 'optional', stylesheet: true
end
