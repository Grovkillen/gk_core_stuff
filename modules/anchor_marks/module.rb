# frozen_string_literal: true

module GkCoreStuff
  # anchor_marks (step 09 of the proposal view_hooks, redmine/core_proposals/view_hooks/stege/09_anchor_marks.patch):
  # fixed marks on parts of core's pages that a plugin changes, so that it finds them by what they are and never by
  # their word, their look, their place or a guessed nesting. Only classes, ids and data attributes; no hooks, nothing
  # that shows. The marks (MARKS below says which view has which):
  #   h1.site-title                        the header's title (layouts/base)
  #   h2.issue-heading, h3.subject-heading the issue page's title and subject (issues/show, IssuesHelper)
  #   th.current-status, td.current-status the name column's cells in the workflow matrix's heading (workflows/_form)
  #   th.field-name, td.field-name         the name column's cells in the field permissions matrix's heading
  #                                        (workflows/permissions)
  #   data-report-column (status, open, closed, total), data-status-id, data-status-closed
  #                                        every heading, count and total cell of the detailed issue report
  #                                        (reports/_details)
  #   tr[data-attachment-id]               each row of an attachment list (attachments/_links)
  #   p[data-field=<attribute>]            the issue form's attribute rows: status_id, priority_id, assigned_to_id,
  #                                        category_id, fixed_version_id, parent_issue_id, start_date, due_date,
  #                                        estimated_hours, done_ratio (issues/_attributes); estimated_hours and
  #                                        done_ratio also in the issue bulk edit form (issues/bulk_edit)
  #   th/td.scm_name, .scm_command, .scm_version (and .scm_path where the series has the column)
  #                                        the version control table (settings/_repositories)
  #   a[data-query-action=apply|clear]     the query form's Apply and Clear (queries/_query_form, the Gantt chart's and
  #                                        the calendar's form)
  #   span[data-query-part=view-options]   the Gantt chart's and the calendar's own controls (months, month, year)
  #   li[data-menu-item=delete]            the issue context menu's Delete, also when it is disabled
  #   fieldset[data-section=attributes]    the issue edit form's attributes box (issues/_edit)
  #   a#issue_description_edit_link        the link that opens the description in the edit form (issues/_form)
  #   a[data-section-action=add]           the Add links of the issue page's subtasks and related issues
  #   input[data-form-action=save]         the Save button of the issue and time entry bulk edit forms (edit mode
  #                                        only) and of every settings form, the plugins' included
  # The views are core's own with the step's lines added, one copy per series in views/<series>/, made by
  # pipeline/scripts/development/core_views.ps1 (never by hand; SOURCE.yml says from which zip and patches). Views that
  # earlier steps also change are built on their lines (layouts/base and issues/show on step 01's and 08's,
  # context_menus/issues on 04's, issues/_form on 05's, issues/_subtasks and _relations on 08's), so the folder stands
  # before theirs. Where trunk changes a helper, the series' copy says the same in the view (issues/_subtasks), or a
  # prepend here does what trunk's helper does: the subject's class (IssuesHelper) and the data attributes a view gives
  # toggle_link (ApplicationHelper; the relations' Add link).
  # Always on; it stands aside the day core has the step (compat's anchor_marks).
  module AnchorMarks
    # The step adds no hooks (the settings page lists hooks in use per step)
    HOOKS = [].freeze
    # The marks by view, for the docs and the scenarios; the names consumers use
    MARKS = {
      'layouts/base' => ['h1.site-title'],
      'issues/show' => ['h2.issue-heading', 'h3.subject-heading'],
      'workflows/_form' => ['th.current-status', 'td.current-status'],
      'workflows/permissions' => ['th.field-name', 'td.field-name'],
      'reports/_details' => ['[data-report-column]', '[data-status-id]', '[data-status-closed]'],
      'attachments/_links' => ['tr[data-attachment-id]'],
      'issues/_attributes' => ['p[data-field]'],
      'settings/_repositories' => ['.scm_name', '.scm_command', '.scm_version', '.scm_path'],
      'queries/_query_form' => ['a[data-query-action=apply]', 'a[data-query-action=clear]'],
      'gantts' => ['span[data-query-part=view-options]', 'a[data-query-action=apply]', 'a[data-query-action=clear]'],
      'calendars/show' => ['span[data-query-part=view-options]', 'a[data-query-action=apply]', 'a[data-query-action=clear]'],
      'context_menus/issues' => ['li[data-menu-item=delete]'],
      'issues/_edit' => ['fieldset[data-section=attributes]'],
      'issues/_form' => ['a#issue_description_edit_link'],
      'issues/_subtasks' => ['a[data-section-action=add]'],
      'issues/_relations' => ['a[data-section-action=add]'],
      'issues/bulk_edit' => ['input[data-form-action=save]', 'p[data-field]'],
      'timelog/bulk_edit' => ['input[data-form-action=save]'],
      'settings' => ['input[data-form-action=save]']
    }.freeze
    SUBJECT_CLASS = 'subject-heading'

    def self.views_dir = GkCoreStuff.series_views(:anchor_marks)

    # Prepended on IssuesHelper: the subject's heading with its class, as trunk's helper with the step draws it
    module IssuesHelperPatch
      def render_issue_subject_with_tree(issue)
        return super unless GkCoreStuff.on?(:anchor_marks)

        s = +''
        ancestors = issue.root? ? [] : issue.ancestors.visible.to_a
        ancestors.each do |ancestor|
          s << '<div>' + content_tag('p', link_to_issue(ancestor, project: (issue.project_id != ancestor.project_id)))
        end
        s << '<div>'
        s << content_tag('h3', h(issue.subject), class: SUBJECT_CLASS)
        s << ('</div>' * (ancestors.size + 1))
        s.html_safe
      end
    end

    # Prepended on ApplicationHelper: trunk's toggle_link with the step passes a :data option on to its link. Core's
    # toggle_link in a series may pass nothing on (6.0 and 6.1 do not even pass :class), so the data attributes are
    # handed to the one link_to the helper draws, and whatever else core's helper does stays core's.
    module ApplicationHelperPatch
      def toggle_link(name, id, options = {})
        data = options.is_a?(Hash) ? options[:data] : nil
        return super if data.nil? || data.empty? || !GkCoreStuff.on?(:anchor_marks)

        @gk_core_stuff_link_data = data
        super(name, id, options.except(:data))
      ensure
        @gk_core_stuff_link_data = nil
      end

      def link_to(name = nil, options = nil, html_options = nil, &block)
        data = @gk_core_stuff_link_data
        return super if data.nil? || block || !(html_options.nil? || html_options.is_a?(Hash))

        @gk_core_stuff_link_data = nil
        html = (html_options || {}).dup
        html[:data] = (html[:data] || {}).merge(data)
        super(name, options, html)
      end
    end
  end

  # Always on, without a setting: the marks are for other plugins and change nothing until one reads them
  register :anchor_marks, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:anchor_marks) }, always: true do
    if GkCoreStuff.prepend_series_views(:anchor_marks, replaces: %i[layout_hooks action_menus form_hooks section_marks], adds: :marks)
      ::IssuesHelper.prepend(AnchorMarks::IssuesHelperPatch) unless ::IssuesHelper < AnchorMarks::IssuesHelperPatch
      ::ApplicationHelper.prepend(AnchorMarks::ApplicationHelperPatch) unless ::ApplicationHelper < AnchorMarks::ApplicationHelperPatch
    end
  end
end
