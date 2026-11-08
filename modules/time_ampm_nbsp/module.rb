# frozen_string_literal: true

module GkCoreStuff
  # time_ampm_nbsp. Core's Redmine::I18n#format_time joins them with an ordinary space (the locale's time format "%I:%M
  # %p" in en, en-GB, ar, el, fa, hr, mn, ro, sq and ta-IN, or Setting.time_format "%I:%M %p"), so a narrow cell breaks
  # there.
  # The upstream form is patch/time_ampm_nbsp-<series>.diff: format_time puts a no-break space before %p or %P in the
  # format it uses. Here the same is done to the format, never to the text core returns: while core's format_time runs,
  # the time format it hands to I18n.l (Setting.time_format, or the locale's time.formats.<name> for a symbol) gets
  # U+00A0 instead of the ordinary spaces before the %p or %P directive. So nothing depends on the words of a locale's
  # AM/PM marker or on what format_time returns; a format without %p (a 24-hour clock) is left as it is. The result is a
  # plain String as before. A CSV keeps the ordinary space (QueriesHelper#csv_value), so a spreadsheet reads the time
  # as before. Idempotent: when core has the fix the format has no ordinary space before %p left to replace.
  module TimeAmpmNbsp
    NBSP = " " unless const_defined?(:NBSP, false)
    # the ordinary spaces before a strftime %p or %P directive (with its flags, %^p, %-P and so on)
    BEFORE_AMPM = /[ \t]+(?=%[-_0^#]*[pP])/ unless const_defined?(:BEFORE_AMPM, false)

    class << self
      # A scenario (or a test) can ask for the module on or off for a block without touching the instance's settings
      def with(on)
        old = Thread.current[:gk_core_stuff_tan]
        Thread.current[:gk_core_stuff_tan] = on ? '1' : '0'
        yield
      ensure
        Thread.current[:gk_core_stuff_tan] = old
      end

      def on?
        o = Thread.current[:gk_core_stuff_tan]
        o ? o == '1' : GkCoreStuff.appearance_on?(:time_ampm_nbsp)
      end

      # Only the I18n.l calls made inside core's format_time are touched
      def inside_format_time
        old = Thread.current[:gk_core_stuff_tan_fmt]
        Thread.current[:gk_core_stuff_tan_fmt] = true
        yield
      ensure
        Thread.current[:gk_core_stuff_tan_fmt] = old
      end

      def inside_format_time? = Thread.current[:gk_core_stuff_tan_fmt] == true

      # The format I18n.l gets for a time: a symbol is resolved in the locale's time.formats as I18n would, and the
      # spaces before %p or %P become U+00A0. Anything else (a date, no format found, no %p) is handed on unchanged.
      def format_for(object, format, locale)
        return format unless plain?(object) || object.is_a?(::DateTime)

        str = format.is_a?(::Symbol) || format.nil? ? ::I18n.t(:"time.formats.#{format || :default}", locale: locale, default: nil) : format
        return format unless str.is_a?(::String) && str.match?(BEFORE_AMPM)

        str.gsub(BEFORE_AMPM, NBSP)
      end

      def plain?(value) = value.is_a?(::Time) || (defined?(::ActiveSupport::TimeWithZone) && value.is_a?(::ActiveSupport::TimeWithZone))
    end

    # Redmine::I18n#format_time: core's own method, with the format's space before AM/PM made a no-break space
    module I18nPatch
      def format_time(time, include_date = true, user = nil)
        TimeAmpmNbsp.on? ? TimeAmpmNbsp.inside_format_time { super } : super
      end
    end

    # I18n.l and I18n.localize: the format is changed only inside format_time (I18n's alias l points at the original
    # localize, so both names are taken)
    module LocalizePatch
      def localize(object, locale: nil, format: nil, **options)
        format = TimeAmpmNbsp.format_for(object, format, locale || ::I18n.locale) if TimeAmpmNbsp.inside_format_time?
        super
      end

      def l(object, locale: nil, format: nil, **options)
        localize(object, locale: locale, format: format, **options)
      end
    end

    # A time in a CSV keeps the ordinary space, as the patch's csv_value does
    module QueriesHelperPatch
      def csv_value(column, object, value)
        s = super
        s.is_a?(String) && TimeAmpmNbsp.plain?(value) ? s.tr(NBSP, ' ') : s
      end
    end
  end

  # Off from the start: it changes how core's pages read; the administrator sets its appearance setting
  register :time_ampm_nbsp, issue: nil, defaults: {}, in_core: -> { false } do
    # Redmine::I18n is included in helpers, controllers, models and the mailer; a prepend reaches them all (Ruby 3)
    ::Redmine::I18n.prepend(TimeAmpmNbsp::I18nPatch) unless ::Redmine::I18n < TimeAmpmNbsp::I18nPatch
    ::I18n.singleton_class.prepend(TimeAmpmNbsp::LocalizePatch) unless ::I18n.singleton_class < TimeAmpmNbsp::LocalizePatch
    ::QueriesHelper.prepend(TimeAmpmNbsp::QueriesHelperPatch) unless ::QueriesHelper < TimeAmpmNbsp::QueriesHelperPatch
  end
end
