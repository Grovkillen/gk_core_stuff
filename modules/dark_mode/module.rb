# frozen_string_literal: true

module GkCoreStuff
  # dark_mode: Redmine's own pages in a dark mode that follows the device. On, the page is dark while the phone's or the
  # computer's own setting (prefers-color-scheme) says dark and light while it says light; off, the page is always
  # light. A look like the others (Looks), kept in GK Records' register: off (no dark mode at all), optional (each person
  # chooses light, dark or automatic under My account, Appearance) or forced (the administrator's choice for everyone);
  # also for someone not logged in, by the instance's level and the administrator's choice. The choice is the look's own
  # value (VALUE), automatic unless chosen, so that a person who has not chosen follows the device.
  # Written as a candidate for Redmine: the stylesheets use core's own ids and classes and Open Color directly, and draw
  # only under the class dark-mode on html; the one sheet for an older series that compat draws the way 7.0 does
  # (CORE_VARS) also needs compat's class gk-core-vars, and is not part of the candidate. A short script in the head
  # sets the class before the first paint, from the device, and again when the device changes. data-dark-mode="on" or
  # "off" on html keeps the class on or off whatever the device says, and the script follows the attribute when it
  # changes on an open page. The choice (light, dark or automatic) is put on the attribute before the class is set; a
  # button elsewhere that changes the choice changes the attribute on the open page. One sheet for every series,
  # and one for the series where core's markup or colours differ, chosen by compat (series_dir on
  # modules/dark_mode/series, as the modules' copies of core's views), and one for an older series that compat draws
  # the way 7.0 does (CORE_VARS).
  module DarkMode
    CLASS = 'dark-mode'
    STYLESHEET = 'gk_core_stuff_dark_mode'
    SERIES = File.expand_path('series', __dir__)
    # The attribute on html that says on or off whatever the device says; without it the device decides
    ATTRIBUTE = 'data-dark-mode'
    # A person's choice and what it puts on the attribute: dark is on, light is off, automatic takes the attribute away
    # so that the device decides
    CHOICES = { 'light' => 'off', 'dark' => 'on', 'auto' => nil }.freeze
    # The look's row in GK Records' register and its value that holds the choice: the person's own under optional
    # (automatic until they choose), the administrator's under forced and for someone not logged in
    ROW = 'core_stuff.dark_mode'
    VALUE = 'mode'
    DEFAULT = 'auto'
    # the class from the device's setting, kept in step with it; the attribute says on or off instead, and a change of
    # the attribute on an open page (a person's new choice) sets the class again
    SCRIPT = "(function(h,m){function s(){var o=h.getAttribute('#{ATTRIBUTE}');h.classList.toggle('#{CLASS}',o==='on'||(o!=='off'&&!!(m&&m.matches)));}" \
             "s();if(m&&m.addEventListener){m.addEventListener('change',s);}" \
             "if(window.MutationObserver){new MutationObserver(s).observe(h,{attributes:true,attributeFilter:['#{ATTRIBUTE}']});}})(document.documentElement," \
             "window.matchMedia?window.matchMedia('(prefers-color-scheme: dark)'):null);"

    # Who else draws dark mode: another plugin (a theme that draws the mode) announces itself here once, with a block
    # that answers, while the page is drawn, whether it draws dark mode for this person and page. Asked at drawing time,
    # so the order of the plugins' head hooks does not matter. While one answers yes, the head links only the script that
    # sets the class, never the sheets: the class and the mode stay this module's, and only the drawing is the other's.
    # The register holds the name each plugin announced itself with, and its block (kept when this file is read again)
    module_function

    def drawn_by_register = (@drawn_by ||= {})

    # The look on for the person, and only with the gate open: with the gate closed the dark mode draws nothing
    def on?(user) = GkCoreStuff.open? && Looks.on_for?(:dark_mode, user)

    #   GkCoreStuff::DarkMode.drawn_by(:gk_theme_engine) { |user, page| ... }
    # Announces that another plugin may draw dark mode; the block answers true for a person and page it draws. Announced
    # again under the same name it replaces the earlier block (a reload in development)
    def drawn_by(name, &answer)
      raise ArgumentError, 'a block that answers' unless answer

      drawn_by_register[name.to_sym] = answer
    end

    # Whether another plugin draws dark mode for this person and page; an answer that fails counts as no, so that the
    # sheets are linked as before
    def drawn_elsewhere?(user, page = nil)
      drawn_by_register.each_value.any? do |answer|
        answer.call(user, page) == true
      rescue StandardError
        false
      end
    end

    # The choice for the person, from the look's own value in GK Records' register. Under optional a logged in person
    # gets their own choice, and automatic until they choose, whatever the administrator's value is: whoever has not
    # chosen follows the device. Under forced, and for someone not logged in, the administrator's value
    # (person_value), automatic until changed. nil without the register, for a value that is no choice, or when the
    # register fails, and the device decides as before. Whether the look is on for the person at all is on?'s to say
    def choice(user)
      r = GkCoreStuff.respond_to?(:appearance_settings) ? GkCoreStuff.appearance_settings : nil
      return nil unless r

      c = own_choice?(r, user) ? (r.person_choice(ROW, user)[:values] || {})[VALUE] || DEFAULT : r.person_value(ROW, VALUE, user)
      CHOICES.key?(c.to_s) ? c.to_s : nil
    rescue StandardError
      nil
    end

    # Whether the person's own choice holds: the look optional and someone logged in (core's anonymous user answers
    # logged? false)
    def own_choice?(register, user)
      register.mode(ROW) == 'optional' && !user.nil? && (!user.respond_to?(:logged?) || user.logged?)
    end

    # A choice's word, from this plugin's own locale keys
    def word(choice) = ::I18n.t(:"label_gk_core_stuff_dark_mode_#{choice}", default: choice.to_s)

    # The value under the look's row: the three choices, each person's own under optional
    def values
      { VALUE => { kind: :choice, default: DEFAULT, person: true, label: :label_gk_core_stuff_dark_mode_mode,
                   info: :text_gk_core_stuff_dark_mode_choice_info, choices: -> { CHOICES.keys.map { |c| [word(c), c] } } } }
    end

    # The choice on the attribute, before the script sets the class: dark and light set it, automatic takes it away;
    # nothing without a choice
    def choice_js(choice)
      return '' unless CHOICES.key?(choice.to_s)

      v = CHOICES[choice.to_s]
      v ? "document.documentElement.setAttribute('#{ATTRIBUTE}','#{v}');" : "document.documentElement.removeAttribute('#{ATTRIBUTE}');"
    end

    # The head's script for the person: their choice on the attribute, then the script that sets the class
    def script_for(user) = "#{choice_js(choice(user))}#{SCRIPT}"

    # The running series' own sheet (gk_core_stuff_dark_mode_<major>_<minor>), when compat says the series has one; nil
    # without compat or for a series without differences
    def series_sheet
      return nil unless defined?(::GkCompat) && ::GkCompat.respond_to?(:series_dir)

      dir = ::GkCompat.series_dir(SERIES)
      dir ? "#{STYLESHEET}_#{File.basename(dir).tr('.', '_')}" : nil
    end

    # What an older series needs while GK Compat draws it the way 7.0 does (html.gk-core-vars): the 7.0 sheet's rules
    # under both classes. Linked in every series, after the series' own sheet; it draws only under compat's class, and
    # in 7.0 it repeats the 7.0 sheet with the same weight
    CORE_VARS = "#{STYLESHEET}_core_vars"

    # The sheets in the order they load: the one for every series, the series' own, then the one under compat's class
    def sheets = [STYLESHEET, series_sheet, CORE_VARS].compact

    # The part for core's sheets that a page adds to its head after the head hook (context_menu.css, jstoolbar.css):
    # it goes into the page's own header_tags, after them, so that its rules have core's weight and win by order
    LATE = "#{STYLESHEET}_late"

    def link(view, sheet) = view.stylesheet_link_tag(sheet, plugin: 'gk_core_stuff', media: 'screen')

    # Only the sheets, on screen (a printed page is core's light one), for a plugin that sets the class itself. page is
    # the view the head hook was called from (context[:hook_caller]): the late sheet is added to its header_tags, which
    # core's layout yields after the hook. Without a page the late sheet follows the others here. Nothing with the gate
    # closed, also when another plugin asks for the sheets
    def stylesheet_tags(view, page = nil)
      return ''.html_safe unless GkCoreStuff.open?

      tags = view.safe_join(sheets.map { |s| link(view, s) }, "\n")
      return tags + "\n".html_safe + link(view, LATE) unless page.respond_to?(:content_for) && page.respond_to?(:view_flow)

      page.content_for(:header_tags, link(view, LATE))
      tags
    end

    # The head's part while the look is on for the person: the sheets and the script; only the script while another
    # plugin draws dark mode for the person and page (drawn_elsewhere?); nothing while it is off or the gate is closed
    def head_tag(view, user = User.current, page = nil)
      return ''.html_safe unless GkCoreStuff.open? && on?(user)

      script = %(<script>#{script_for(user)}</script>).html_safe # gk-u U2: the class must stand before the first paint, or a dark page flashes light
      return script if drawn_elsewhere?(user, page)

      stylesheet_tags(view, page) + "\n".html_safe + script
    end
  end

  Looks.register :dark_mode, anonymous: true, values: DarkMode.values, in_core: -> { GkCoreStuff.core_has?(:dark_mode) }
end
