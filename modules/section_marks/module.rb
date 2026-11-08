# frozen_string_literal: true

module GkCoreStuff
  # section_marks (step 08 of the proposal view_hooks, redmine/core_proposals/view_hooks/stege/08_section_marks.patch):
  # fixed marks on the issue page's sections, so that a plugin finds a section by what it is and not by its label's
  # word or its bold text. The container of each section gets data-section (description on div.description,
  # attachments on a new div around the files' heading and list, subtasks on #issue_tree, relations on #relations), and
  # its heading paragraph the class section-heading. No hooks, and nothing that shows: without a plugin's CSS or
  # JavaScript that reads them the page is core's. The views are core's own with the step's lines added, one copy per
  # series in views/<series>/, made by pipeline/scripts/development/core_views.ps1 (never by hand; SOURCE.yml says from
  # which zip and patches). issues/show.html.erb is also changed by step 01, so its copy here is built on step 01's
  # (layout_hooks) and has those hooks too; the folder stands before layout_hooks' so that this copy is the one drawn.
  # Always on; it stands aside the day core has the step (compat's section_marks).
  module SectionMarks
    # The step adds no hooks (the settings page lists hooks in use per step)
    HOOKS = [].freeze
    # The sections and their mark (data-section), and the heading's class
    SECTIONS = %w[description attachments subtasks relations].freeze
    HEADING_CLASS = 'section-heading'

    def self.views_dir = GkCoreStuff.series_views(:section_marks)
  end

  # Always on, without a setting: the marks are for other plugins and change nothing until one reads them
  register :section_marks, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:section_marks) }, always: true do
    GkCoreStuff.prepend_series_views(:section_marks, replaces: %i[layout_hooks], adds: :marks)
  end
end
