# frozen_string_literal: true

module GkCoreStuff
  # time_ampm_nbsp. Core's Redmine::I18n#format_time joins them with an ordinary space (the locale's time format "%I:%M
  # %p" in en, en-GB, ar, el, fa, hr, mn, ro, sq and ta-IN, or Setting.time_format "%I:%M %p"), so a narrow cell breaks
  # there.
  # The upstream form is patch/time_ampm_nbsp-<series>.diff: format_time puts a no-break space before %p or %P in the
  # format it uses. Here the same result is hooked in with prepend: the ordinary space (or spaces) between the last
  # digit of the time and the locale's AM/PM marker (time.am, time.pm, in any case) becomes U+00A0. The result is a
  # plain String as before. A CSV keeps the ordinary space (QueriesHelper#csv_value), so a spreadsheet reads the time
  # as before. Idempotent: when core has the fix there is no ordinary space left to replace.
  module TimeAmpmNbsp
    NBSP = "\u00A0" unless const_defined?(:NBSP, false)

    @patterns ||= {}

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
        o ? o == '1' : GkCoreStuff.on?(:time_ampm_nbsp)
      end

      # The ordinary spaces between a time's last digit and the current locale's AM/PM marker, or nil when the locale
      # has none (sv: am and pm are blank)
      def pattern
        marks = %w[am pm].map { |k| ::I18n.t("time.#{k}", default: '').to_s }.reject(&:empty?)
        return nil if marks.empty?

        @patterns[marks] ||= begin
          words = marks.flat_map { |m| [m, m.upcase, m.downcase] }.uniq.sort_by { |w| -w.length }
          Regexp.new("(?<=\\d)[ \\t]+(?=(?:#{words.map { |w| Regexp.escape(w) }.join('|')})(?![[:alpha:]]))")
        end
      end

      def join(str)
        return str unless str.is_a?(String) && (re = pattern)

        str.gsub(re, NBSP)
      end

      def plain?(value) = value.is_a?(::Time) || (defined?(::ActiveSupport::TimeWithZone) && value.is_a?(::ActiveSupport::TimeWithZone))
    end

    # Redmine::I18n#format_time: core's result with the no-break space before AM/PM
    module I18nPatch
      def format_time(time, include_date = true, user = nil)
        s = super
        TimeAmpmNbsp.on? ? TimeAmpmNbsp.join(s) : s
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

  # On from the start (a fix, not a function to grow into); switchable as the other modules
  register :time_ampm_nbsp, issue: nil, defaults: { 'time_ampm_nbsp' => '1' }, in_core: -> { false } do
    # Redmine::I18n is included in helpers, controllers, models and the mailer; a prepend reaches them all (Ruby 3)
    ::Redmine::I18n.prepend(TimeAmpmNbsp::I18nPatch) unless ::Redmine::I18n < TimeAmpmNbsp::I18nPatch
    ::QueriesHelper.prepend(TimeAmpmNbsp::QueriesHelperPatch) unless ::QueriesHelper < TimeAmpmNbsp::QueriesHelperPatch
  end
end
