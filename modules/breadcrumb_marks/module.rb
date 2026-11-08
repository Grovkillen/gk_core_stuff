# frozen_string_literal: true

module GkCoreStuff
  # breadcrumb_marks: the project's identifier on each project link of the header's breadcrumb, data-project, so that
  # a plugin knows which project a link of the breadcrumb leads to from the mark and never from the links' order, the
  # separators or the ellipsis core puts in when there are many ancestors. Core draws the breadcrumb with
  # ApplicationHelper#page_header_title, whose links to the root (a.root) and the ancestors (a.ancestor) come from
  # link_to_project; while page_header_title draws, link_to_project gets the mark with core's own attributes. An
  # archived project, which core writes as text, gets none, and the current project (span.current-project) is the
  # page's own @project. Nothing shows. A prepend on core's helper, no copied views.
  # Always on; it stands aside the day core has the mark (compat's breadcrumb_marks).
  module BreadcrumbMarks
    ATTRIBUTE = 'data-project'

    # The attributes of a breadcrumb link: core's, with the project's identifier
    def self.link_options(html_options, project)
      (html_options || {}).merge(ATTRIBUTE => project.identifier.to_s)
    end

    # Prepended on ApplicationHelper
    module ApplicationHelperPatch
      def page_header_title
        return super unless GkCoreStuff.on?(:breadcrumb_marks)

        @gk_core_stuff_breadcrumb = true
        super
      ensure
        @gk_core_stuff_breadcrumb = nil
      end

      def link_to_project(project, options = {}, html_options = nil)
        return super unless @gk_core_stuff_breadcrumb && project.respond_to?(:identifier) &&
                            (html_options.nil? || html_options.is_a?(Hash))

        super(project, options, BreadcrumbMarks.link_options(html_options, project))
      end
    end
  end

  # Always on, without a setting: the mark is for other plugins and changes nothing that shows
  register :breadcrumb_marks, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:breadcrumb_marks) }, always: true do
    ::ApplicationHelper.prepend(BreadcrumbMarks::ApplicationHelperPatch) unless ::ApplicationHelper < BreadcrumbMarks::ApplicationHelperPatch
  end
end
