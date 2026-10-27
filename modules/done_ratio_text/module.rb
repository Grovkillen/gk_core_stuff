# frozen_string_literal: true

module GkCoreStuff
  # done_ratio_text (redmine.org #5284): % done as text where a progress bar shows a single value in a list. The
  # upstream form is patch/done_ratio_text-<series>.diff: progress_bar takes text: true and places the value as set in
  # Administration > Settings > Issue tracking (progress_bar_text: right, over, under, hidden or blank for none;
  # progress_bar_text_zero and _full for 0 % and 100 %). Here the same is hooked in with prepend and read from this
  # plugin's settings, until core has it (then Setting knows progress_bar_text and nothing is hooked in).
  module DoneRatioText
    POSITIONS = %w[right over under hidden].freeze

    class << self
      # A scenario (or a test) can ask for other settings for a block without touching the instance's settings
      def with(**over)
        old = Thread.current[:gk_core_stuff_drt]
        Thread.current[:gk_core_stuff_drt] = over.transform_keys(&:to_s)
        yield
      ensure
        Thread.current[:gk_core_stuff_drt] = old
      end

      def value(key)
        o = Thread.current[:gk_core_stuff_drt]
        o&.key?(key) ? o[key].to_s : GkCoreStuff.settings[key].to_s
      end

      def on? = Thread.current[:gk_core_stuff_drt]&.key?('done_ratio_text') ? value('done_ratio_text') == '1' : GkCoreStuff.on?(:done_ratio_text)

      # The position, or nil when no text is shown for this value
      def position_for(pct)
        return nil unless on?

        pos = value('done_ratio_text_position')
        return nil unless POSITIONS.include?(pos)
        return nil if pct.zero? && value('done_ratio_text_zero') != '1'
        return nil if pct == 100 && value('done_ratio_text_full') != '1'

        pos
      end

      # The position set, whatever the value: a bar whose text is left out (0 % or 100 %) still takes the same place,
      # so that every bar in a column has the same width and stands in the same place
      def layout
        return nil unless on?

        pos = value('done_ratio_text_position')
        POSITIONS.include?(pos) ? pos : nil
      end
    end

    # ApplicationHelper#progress_bar_with_text as in the diff, reading our settings instead of Setting
    module ApplicationHelperPatch
      def progress_bar(pcts, options = {})
        return super unless options.key?(:text)

        opts = options.except(:text)
        return super(pcts, opts) unless options[:text]

        pct = Array(pcts).first.to_f.floor
        pos = DoneRatioText.layout
        return super(pcts, opts) unless pos

        shown = DoneRatioText.position_for(pct)
        bar = String.new(super(pcts, opts.merge(legend: nil))).sub(%r{<p class="percent"></p>\z}, '').html_safe
        css = pos == 'hidden' ? 'progress-text hidden-for-sighted' : 'progress-text'
        # a light plate behind the text on the bar, when the instance chooses it (core_stuff only; core's form keeps
        # the text's white glow)
        css += ' gk-core-stuff-progress-plate' if pos == 'over' && DoneRatioText.value('done_ratio_text_plate') == '1'
        # a value whose text is left out keeps an empty place for it
        text = shown ? content_tag('span', "#{pct}%", class: css) : content_tag('span', '', class: "#{css} progress-text-none", 'aria-hidden': 'true')
        content_tag('div', bar + text, class: "progress-with-text progress-text-#{pos}")
      end
    end

    module QueriesHelperPatch
      def column_value(column, item, value)
        return super unless column.name == :done_ratio && !value.nil? && DoneRatioText.on?

        progress_bar(value, text: true)
      end
    end

    # The custom field format Progress bar, where core has it (compat's progressbar_field_format): text in lists, the legend
    # on the object's own page
    module ProgressbarFormatPatch
      def formatted_value(view, custom_field, value, customized = nil, html = false)
        return super unless html && view.action_name != 'show' && DoneRatioText.on?

        view.progress_bar(value.to_i, text: true)
      end
    end
  end

  # Off for a new installation: % done is not part of the way of working on day one; the administrator switches it
  # on in the plugin's settings
  register :done_ratio_text, issue: 5284,
           defaults: { 'done_ratio_text' => '0', 'done_ratio_text_position' => 'right',
                       'done_ratio_text_zero' => '1', 'done_ratio_text_full' => '1', 'done_ratio_text_plate' => '0' },
           in_core: -> { GkCoreStuff.core_has?(:progress_bar_text) } do
    ::ApplicationHelper.prepend(DoneRatioText::ApplicationHelperPatch) unless ::ApplicationHelper < DoneRatioText::ApplicationHelperPatch
    ::QueriesHelper.prepend(DoneRatioText::QueriesHelperPatch) unless ::QueriesHelper < DoneRatioText::QueriesHelperPatch
    # compat knows whether core has the format; without compat the format is left alone
    if GkCoreStuff.core_has?(:progressbar_field_format) && !(::Redmine::FieldFormat::ProgressbarFormat < DoneRatioText::ProgressbarFormatPatch)
      ::Redmine::FieldFormat::ProgressbarFormat.prepend(DoneRatioText::ProgressbarFormatPatch)
    end
  end
end
