# frozen_string_literal: true

module GkCoreStuff
  # chart_colors: Redmine's own charts in the colours of the surface that is drawn. While GK Core Stuff's dark mode makes
  # the page dark, or a theme says the tone of the surface it draws (GK GUI Stuff's tone attribute on html), the series
  # of core's Chart.js charts take the category roles 1 to 10 in order and start over after ten: the edge in the role,
  # the fill in its soft tone. The text takes ui-text-soft, the grid ui-divider, the axes ui-frame, and the tooltip
  # ui-raised with ui-text. In the light without a theme nothing changes, and a page whose mode changes is drawn again.
  # As a part of its own, the version control's revision graph and the marks in the Gantt chart's drawing (the relation
  # lines, and the progress line core draws in the same drawing) keep their colours, which are data, but each mark is
  # given the same hue at a lightness that holds 3:1 against the surface it stands on. Core gives no single mark in
  # these drawings an id, a class or a data attribute, so no mark is picked out by its colour. The Gantt chart's today
  # line has an id of its own, and core reads the progress line's colour from that element each time it draws the line:
  # the today line's edge is held to 3:1 against its ground by the same rule, by that id, so the progress line core
  # draws from then on follows, and one already drawn is held as a mark in the drawing. The colour boxes in the Gantt
  # chart's filter are left as core draws them.
  # The look is off until someone switches it on (config/registrations.yml); core's own chart colours hold until then.
  # Not a single colour stands here or in the script: the script reads the roles by name (GK GUI Stuff's role_var) and
  # resolves them on the page.
  # Stable anchors only: Chart.js's own API (a plugin registered with Chart.register, the instances in Chart.instances,
  # each chart's config), core's charts by their purposeful ids (the canvas ids the views give each chart, the same in
  # every series), the revision graph by its class revision-graph, the Gantt chart's drawing by its id gantt_draw_area
  # and its today line by its id today_line. How Chart.js is reached is series knowledge and comes from GK Compat
  # (chart_js_module: a module through the import map, or the global Chart a classic script sets).
  # Kept apart from dark_mode, which is the candidate for Redmine.
  module ChartColors
    KEY = 'chart_colors'
    # The ids core's views give the canvas of each chart: the detailed issue report (one per kind of detail, and the one
    # by status) and the version control's statistics: app/views/reports/_details.html.erb draws
    # canvas#issues_by_<detail> and canvas#issues_by_status (the details ReportsController#issue_report_details knows),
    # and app/views/repositories/stats.html.erb canvas#commits_per_month and canvas#commits_per_author. The test compares
    # DETAILS with the controller of the Redmine GK_REDMINE_ROOT names.
    DETAILS = %w[tracker version priority category assigned_to author subproject status].freeze
    CHARTS = (DETAILS.map { |d| "issues_by_#{d}" } + %w[commits_per_month commits_per_author]).freeze
    # The revision graph's holder (div#holder.revision-graph in app/views/repositories/_revision_graph.html.erb) and the
    # Gantt chart's drawing (div#gantt_draw_area in app/views/gantts), the same in the three series
    GRAPH_CLASS = 'revision-graph'
    GANTT_ID = 'gantt_draw_area'
    # The Gantt chart's today line (div#today_line in app/views/gantts, drawn while today is within the chart's dates),
    # the same in the three series. Core's script takes the progress line's colour from this element
    TODAY_ID = 'today_line'
    # The category roles the series take, in order; the eleventh series takes the first again
    CATEGORIES = 10
    # 3:1, the limit for graphics against the surface (WCAG 1.4.11)
    CONTRAST = 3.0

    module_function

    # The custom property of a role, as GK GUI Stuff names it; nil without GK GUI Stuff
    def role(group, key)
      return nil unless defined?(::GkGuiStuff::Primitives) && ::GkGuiStuff::Primitives.respond_to?(:role_var)

      ::GkGuiStuff::Primitives.role_var(group, key)
    end

    # The custom property of a role's soft tone, named by GK GUI Stuff's own API; nil when GK GUI Stuff declares no soft
    # tone for the role
    def soft(group, key)
      p = ::GkGuiStuff::Primitives if defined?(::GkGuiStuff::Primitives)
      return nil unless p.respond_to?(:role_soft?) && p.respond_to?(:role_var) && p.role_soft?(group, key)

      p.role_var(group, "#{key}-soft")
    end

    # The roles' names for the script: each series a pair of the role and its soft tone. Empty when a role or a soft
    # tone it needs is not there, rather than a guessed name
    def roles
      series = (1..CATEGORIES).map { |n| [role('category', n), soft('category', n)] }
      r = { series: series, text: soft('ui', 'text'), grid: role('ui', 'divider'), axis: role('ui', 'frame'),
            tip: role('ui', 'raised'), tip_text: role('ui', 'text'), surface: role('ui', 'surface') }
      return {} if series.flatten.any?(&:nil?) || r.values.any?(&:nil?)

      r
    end

    # The name of the tone attribute; GK GUI Stuff owns it and this module only reads it
    def tone_attribute = defined?(::GkGuiStuff::Tone) ? ::GkGuiStuff::Tone::ATTRIBUTE : nil

    # Does the running Redmine load Chart.js as a module through the import map? GK Compat's answer, no without it
    def chart_module? = GkCoreStuff.core_has?(:chart_js_module)

    # What the script is given (Looks' options): how Chart.js is reached, what makes the surface dark or toned, where
    # core's charts and graphs are, and the roles by name. Without GK GUI Stuff's roles the script does nothing
    def options
      r = roles
      return {} if r.empty?

      { module: chart_module?, dark: DarkMode::CLASS, tone: tone_attribute, charts: CHARTS, graph: GRAPH_CLASS,
        gantt: GANTT_ID, today: TODAY_ID, contrast: CONTRAST, roles: r }
    end
  end

  Looks.register :chart_colors, script: true, anonymous: true, options: -> { ChartColors.options }
end
