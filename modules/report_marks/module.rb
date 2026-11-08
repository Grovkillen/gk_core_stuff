# frozen_string_literal: true

module GkCoreStuff
  # report_marks: fixed marks on the counts of core's issue reports (Översikt per tracker, version, ... and the detailed
  # table), so that a plugin knows what a column is from the mark and never from its place, its heading's word or a
  # status's name. Core draws every count but the totals row with ReportsHelper#aggregate_link(data, criteria, ...); the
  # criteria say what the count is, and the count is drawn inside a span that says it:
  #   data-report-column  status (one status), open (the open ones), closed (the closed ones) or total (every status)
  #   data-status-id      the status's id, on a status count
  #   data-status-closed  1 for a closed status, 0 for an open one, on a status count
  # The span has no class and no style, so the page looks as core's. The totals row (core's aggregate, a number core
  # also uses in sums and the charts' data) is not marked; a plugin reads a column's kind from the marks in the same
  # table column. A prepend on core's helper, no copied views.
  # Always on; it stands aside the day core has such marks (compat's report_marks).
  module ReportMarks
    COLUMNS = %w[status open closed total].freeze

    module_function

    # The column a count's criteria stand for
    def column(criteria)
      c = criteria.respond_to?(:to_h) ? criteria.to_h.transform_keys(&:to_s) : {}
      return 'status' if c.key?('status_id')
      return 'total' unless c.key?('closed')

      c['closed'].to_s == '1' || c['closed'] == true ? 'closed' : 'open'
    end

    # The span's attributes for a count: the column, and for a status its id and whether it is closed
    def attributes(criteria, closed_ids)
      col = column(criteria)
      out = { 'data-report-column' => col }
      return out unless col == 'status'

      id = criteria.to_h.transform_keys(&:to_s)['status_id']
      out['data-status-id'] = id.to_s
      out['data-status-closed'] = closed_ids.include?(id.to_i) ? '1' : '0'
      out
    end

    # Prepended on ReportsHelper
    module HelperPatch
      def aggregate_link(data, criteria, *args)
        out = super
        gk_core_stuff_report_marks_on? ? gk_core_stuff_report_mark(out, criteria) : out
      end

      # Whether the marks are drawn, asked once per page and not per count
      def gk_core_stuff_report_marks_on?
        @gk_core_stuff_report_marks_on = GkCoreStuff.on?(:report_marks) unless defined?(@gk_core_stuff_report_marks_on)
        @gk_core_stuff_report_marks_on
      end

      # The count inside its mark; a failure leaves core's count as it was
      def gk_core_stuff_report_mark(out, criteria)
        content_tag(:span, out, GkCoreStuff::ReportMarks.attributes(criteria, gk_core_stuff_closed_status_ids))
      rescue StandardError => e
        ::Rails.logger.warn("[gk_core_stuff] report_marks: #{e.class}: #{e.message}") if defined?(::Rails)
        out
      end

      # The closed statuses' ids, read once per page
      def gk_core_stuff_closed_status_ids
        @gk_core_stuff_closed_status_ids ||= ::IssueStatus.where(is_closed: true).pluck(:id)
      end
    end
  end

  # Always on, without a setting: the marks are for other plugins and change nothing that shows
  register :report_marks, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:report_marks) }, always: true do
    ::ReportsHelper.prepend(ReportMarks::HelperPatch) unless ::ReportsHelper < ReportMarks::HelperPatch
  end
end
