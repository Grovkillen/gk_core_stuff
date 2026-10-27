# frozen_string_literal: true

module GkCoreStuff
  # core_stuff in scenarios: expectations that render what core renders, with the module's settings for the
  # expectation only (DoneRatioText.with), so that every position is tried without changing the instance's settings.
  #   cst_done_ratio_text: <right|over|under|hidden|none>, value: 40, position:, zero:, full:, enabled:
  #     the issue list's % done cell for an issue with that value (column_content, as core's list draws it)
  #   cst_done_ratio_text_cf: the same for a custom field of format Progress bar, where core has it (compat)
  #   cst_done_ratio_plain: <value>: progress_bar without text: (the issue page, versions) is core's own output
  module ScenarioRender
    module_function

    def render(inline, locals) = ::IssuesController.renderer.render(inline: inline, locals: locals)

    # Core's own method of a helper, under every module prepended to it (this plugin's and any other's)
    def core_method(helper, name)
      m = helper.instance_method(name)
      m = m.super_method while m && m.owner != helper
      m
    end

    def list_cell(value)
      col = ::IssueQuery.available_columns.detect { |c| c.name == :done_ratio }
      render('<%= column_content(c, i) %>', c: col, i: ::Issue.new(done_ratio: value))
    end

    def cf_cell(value)
      return nil unless GkCoreStuff.core_has?(:progressbar_field_format)

      cf = ::IssueCustomField.new(name: 'gk_core_stuff_field', field_format: 'progressbar')
      render('<%= cf.format.formatted_value(self, cf, v, nil, true) %>', cf: cf, v: value.to_s)
    end

    # What the html shows: the position and the text, or none (also a bar that keeps an empty place for a text left out)
    def found(html)
      return { 'position' => 'none' } if html.include?('progress-text-none')

      pos = html[/progress-with-text progress-text-(\w+)/, 1]
      text = html[%r{<span class="progress-text[^"]*">([^<]*)</span>}, 1]
      pos ? { 'position' => pos, 'text' => text } : { 'position' => 'none' }
    end

    def overrides(e)
      o = {}
      # Off for a new installation: an expectation without enabled: tries the module switched on
      o[:done_ratio_text] = !e.key?('enabled') || e['enabled'] ? '1' : '0'
      o[:done_ratio_text_position] = e['position'].to_s if e.key?('position')
      o[:done_ratio_text_zero] = e['zero'] ? '1' : '0' if e.key?('zero')
      o[:done_ratio_text_full] = e['full'] ? '1' : '0' if e.key?('full')
      o
    end

    def want(e, key)
      pos = e[key].to_s
      pos == 'none' ? { 'position' => 'none' } : { 'position' => pos, 'text' => "#{e['value'].to_i}%" }
    end
  end

  def self.register_scenarios!
    return unless defined?(::GkScenarios::Expect)

    ::GkScenarios::Expect.register('cst_done_ratio_text') do |_ctx, e|
      want = ScenarioRender.want(e, 'cst_done_ratio_text')
      html = DoneRatioText.with(**ScenarioRender.overrides(e)) { ScenarioRender.list_cell(e['value'].to_i) }
      got = ScenarioRender.found(html)
      { 'ok' => got == want, 'want' => want.to_json, 'got' => got.to_json }
    end

    ::GkScenarios::Expect.register('cst_done_ratio_text_cf') do |_ctx, e|
      want = ScenarioRender.want(e, 'cst_done_ratio_text_cf')
      html = DoneRatioText.with(**ScenarioRender.overrides(e)) { ScenarioRender.cf_cell(e['value'].to_i) }
      if html.nil?
        { 'ok' => true, 'want' => want.to_json, 'got' => 'no custom field format Progress bar in this series (compat), nothing to show' }
      else
        got = ScenarioRender.found(html)
        { 'ok' => got == want, 'want' => want.to_json, 'got' => got.to_json }
      end
    end

    ::GkScenarios::Expect.register('cst_done_ratio_plain') do |_ctx, e|
      v = e['cst_done_ratio_plain'].to_i
      html = ScenarioRender.render('<%= progress_bar(v, legend: "#{v}%") %>', v: v)
      got = { 'wrapped' => html.include?('progress-with-text'), 'legend' => html.include?(%(<p class="percent">#{v}%</p>)) }
      want = { 'wrapped' => false, 'legend' => true }
      { 'ok' => got == want, 'want' => want.to_json, 'got' => got.to_json }
    end

    # single_preference: cst_single_preference: cycle, with a user of its own made for the check in a transaction that
    # is rolled back.
    #   stale: one object read the user's preference as empty, another saved one since; the first must get that row,
    #          not make a second
    #   duplicates: two rows already there; the user's preference is the oldest with the newer row's keys merged in, and
    #          one row is left
    ::GkScenarios::Expect.register('cst_single_preference') do |_ctx, e|
      next({ 'ok' => false, 'want' => 'cst_single_preference: cycle', 'got' => e['cst_single_preference'].to_s }) unless e['cst_single_preference'].to_s == 'cycle'
      next({ 'ok' => false, 'want' => 'the module on', 'got' => 'off' }) unless SinglePreference.on?

      checks = []
      ::User.transaction(requires_new: true) do
        u = ::User.new(firstname: 'Prov', lastname: 'Inställning', mail: 'pref.probe@scenario.example')
        u.login = 'scn_pref_probe'
        u.save!
        a = ::User.find(u.id)
        a.preference # read as empty
        b = ::User.find(u.id)
        b.pref[:gk_core_stuff_probe] = '1'
        b.pref.save!
        checks << ['stale reads the saved row', a.pref.id == b.pref.id && a.pref[:gk_core_stuff_probe] == '1']
        checks << ['stale made no second row', ::UserPreference.where(user_id: u.id).count == 1]

        first = ::UserPreference.where(user_id: u.id).first
        extra = ::UserPreference.new(user_id: u.id)
        extra[:gk_core_stuff_probe] = '2'
        extra[:gk_core_stuff_other] = 'x'
        extra.save!(validate: false)
        c = ::User.find(u.id)
        pref = c.pref
        checks << ['duplicates merged into the oldest', pref.id == first.id && pref[:gk_core_stuff_probe] == '2' && pref[:gk_core_stuff_other] == 'x']
        checks << ['one row left', ::UserPreference.where(user_id: u.id).count == 1]
        raise ActiveRecord::Rollback
      end
      failed = checks.reject { |_k, ok| ok }.map(&:first)
      { 'ok' => failed.empty?, 'want' => checks.map(&:first).join(', '), 'got' => failed.empty? ? 'ok' : "not: #{failed.join(', ')}" }
    end

    # time_ampm_nbsp: cst_time_ampm: en | sv, enabled: (true when left out). 10:44 and 22:44 UTC through core's
    # format_time in that locale, read in UTC. en with the module on: no ordinary space before AM/PM, a no-break space
    # there ("10:44{nbsp}AM" when Setting.time_format is blank), and a CSV cell keeps the ordinary space; off: core's
    # own output. sv (24-hour clock): the same with the module on and off. Nothing written.
    # The register of picture sources (avatar_sources): a source added for the user answers before core (Gravatar, the
    # initials in 7.0), a source with nothing lets core answer, an anonymous user never asks the sources, and with the
    # module off core answers. The source is only for this check and is taken away again; nothing is written.
    ::GkScenarios::Expect.register('cst_avatar_source') do |_ctx, e|
      u = e['login'] ? ::User.find_by(login: e['login'].to_s) : ::User.active.where(admin: false).order(:id).first
      next({ 'ok' => false, 'want' => 'a user', 'got' => '-' }) unless u

      mark = 'gk-core-stuff-avatar-check'
      key = 'gk_core_stuff_check'
      checks = []
      begin
        AvatarSources.register(key, position: -1) { |p, opts, view| p.id == u.id ? view.content_tag(:span, '', class: "#{opts[:class]} #{mark}".strip) : nil }
        checks << ['a source answers first', ScenarioRender.render('<%= avatar(u, size: 24) %>', u: u).include?(mark)]
        checks << ['another user: core answers', !ScenarioRender.render('<%= avatar(u, size: 24) %>', u: ::User.where.not(id: u.id).active.first || ::User.anonymous).include?(mark)]
        checks << ['an anonymous user never asks', !ScenarioRender.render('<%= avatar(u, size: 24) %>', u: ::User.anonymous).include?(mark)]
        # the module off for the check; GK Scenarios writes back and empties core's cache of settings afterwards
        ::GkScenarios::Expect.with_setting(:gk_core_stuff, 'avatar_sources' => '0') do
          checks << ['the module off: core answers', !ScenarioRender.render('<%= avatar(u, size: 24) %>', u: u).include?(mark)]
        end
      ensure
        AvatarSources.unregister(key)
      end
      failed = checks.reject(&:last).map(&:first)
      { 'ok' => failed.empty?, 'want' => 'source first, then core; never for anonymous; off is core',
        'got' => failed.empty? ? 'source first, then core; never for anonymous; off is core' : "not: #{failed.join(', ')}" }
    end

    ::GkScenarios::Expect.register('cst_time_ampm') do |_ctx, e|
      loc = e['cst_time_ampm'].to_s
      next({ 'ok' => false, 'want' => 'cst_time_ampm: en | sv', 'got' => loc }) unless %w[en sv].include?(loc)

      on = !e.key?('enabled') || !!e['enabled']
      utc = Object.new
      def utc.convert_time_to_user_timezone(time) = time.utc
      h = ::IssuesController.helpers # QueriesHelper#csv_value with format_time (include_all_helpers is off)
      show = ->(s) { s.to_s.gsub(TimeAmpmNbsp::NBSP, '{nbsp}') }
      times = [Time.utc(2026, 10, 7, 10, 44), Time.utc(2026, 10, 7, 22, 44)]
      checks = []
      seen = []
      ::I18n.with_locale(loc) do
        times.each do |t|
          core = TimeAmpmNbsp.with(false) { h.format_time(t, false, utc) }
          got = TimeAmpmNbsp.with(on) { h.format_time(t, false, utc) }
          seen << show.(got)
          marks = %w[am pm].map { |k| ::I18n.t("time.#{k}", default: '').to_s }.reject(&:empty?)
          ampm = marks.any? && core.match?(/\d (?:#{marks.map { |m| Regexp.escape(m) }.join('|')})/i)
          if !on || !ampm
            checks << ["#{show.(got)} as core's #{show.(core)}", got == core]
          else
            checks << ["#{show.(got)}: no ordinary space before AM/PM", !got.match?(/\d (?:#{marks.map { |m| Regexp.escape(m) }.join('|')})/i)]
            checks << ["#{show.(got)}: core's with a no-break space", got == core.sub(/(?<=\d) +/, TimeAmpmNbsp::NBSP)]
            checks << ["#{show.(got)}: plain String", got.instance_of?(String)]
          end
          next unless ::Setting.time_format.blank?

          want = { 'en' => t.strftime('%I:%M') + (on ? TimeAmpmNbsp::NBSP : ' ') + (t.hour < 12 ? 'AM' : 'PM'), 'sv' => t.strftime('%H:%M') }[loc]
          checks << ["#{show.(got)} is #{show.(want)}", got == want]
        end
        if on && loc == 'en'
          col = ::IssueQuery.available_columns.detect { |c| c.name == :created_on }
          cell = TimeAmpmNbsp.with(true) { h.csv_value(col, ::Issue.new, times.first) }
          plain = TimeAmpmNbsp.with(false) { h.format_time(times.first) }
          checks << ["CSV keeps the ordinary space: #{show.(cell)}", cell == plain]
        end
      end
      failed = checks.reject { |_k, ok| ok }.map(&:first)
      { 'ok' => failed.empty?, 'want' => checks.map(&:first).join(', '), 'got' => failed.empty? ? seen.join(', ') : "not: #{failed.join(', ')}" }
    end

    # footer_version: cst_footer_version: on | off. The head tags a page gets, as the hook gives them, with the module
    # on or off for the check only (FooterVersion.with): on gives Redmine's version (major.minor.tiny) and the script,
    # off gives nothing. With the module's patch in core the module stands aside, and the check says so. Nothing written.
    ::GkScenarios::Expect.register('cst_footer_version') do |_ctx, e|
      want = e['cst_footer_version'].to_s
      next({ 'ok' => false, 'want' => 'cst_footer_version: on | off', 'got' => want }) unless %w[on off].include?(want)
      next({ 'ok' => true, 'want' => want, 'got' => 'core has the setting' }) if GkCoreStuff.in_core?(:footer_version)

      # without the comments development mode puts around a rendered template
      html = FooterVersion.with(want == 'on') { ScenarioRender.render('<%= GkCoreStuff::FooterVersion.head_tags(self) %>', {}) }.gsub(/<!--.*?-->/m, '')
      v = FooterVersion.version
      got = if html.include?(%(data-version="#{v}")) && html.include?('gk_core_stuff_footer_version') then "on #{v}"
            elsif html.strip.empty? then 'off'
            else html.strip[0, 80]
            end
      { 'ok' => got == (want == 'on' ? "on #{v}" : 'off'), 'want' => want == 'on' ? "on #{v}" : 'off', 'got' => got }
    end

    # settings_tabs: cst_settings_tabs: <tab name>, project:, as:, equals: (true when left out). The project's settings
    # tabs as the person gets them (ProjectsHelper#project_settings_tabs, which the settings page renders): a tab a
    # plugin registered is there for the one who may see it and not in core's own list, so it comes through the
    # register; with equals: false it is not there for that person. Nothing written.
    ::GkScenarios::Expect.register('cst_settings_tabs') do |ctx, e|
      name = e['cst_settings_tabs'].to_s
      want = e.key?('equals') ? e['equals'].to_s == 'true' : true
      next({ 'ok' => true, 'want' => name, 'got' => 'core has the register' }) if GkCoreStuff.in_core?(:settings_tabs)
      next({ 'ok' => false, 'want' => "#{name} registered", 'got' => Tabs.registered(:project_settings).map { |t| t[:name] }.join(', ') }) unless Tabs.registered(:project_settings).any? { |t| t[:name] == name }

      project = ::Project.find_by(id: ::GkScenarios::Expect.project_id(ctx, e['project']))
      user = ::User.find_by(login: ::GkScenarios::Expect.login(ctx, e['as']))
      next({ 'ok' => false, 'want' => 'a project and a person', 'got' => '-' }) unless project && user

      core = ScenarioRender.core_method(::ProjectsHelper, :project_settings_tabs)
      out = {}
      ctx.as(user) do
        ::ProjectsController.renderer.render(inline: '<% @project = p; out[:all] = project_settings_tabs; out[:core] = core.bind_call(self) %>',
                                             locals: { p: project, out: out, core: core })
      end
      names = ->(tabs) { Array(tabs).map { |t| t[:name].to_s } }
      got = names.(out[:all]).include?(name)
      checks = [["#{name} #{want ? 'shown' : 'not shown'}", got == want]]
      checks << ["#{name} not in core's own list", !names.(out[:core]).include?(name)]
      failed = checks.reject(&:last).map(&:first)
      { 'ok' => failed.empty?, 'want' => checks.map(&:first).join(', '), 'got' => failed.empty? ? names.(out[:all]).join(', ') : "not: #{failed.join(', ')}" }
    end

    # journal_details: cst_journal_details: <issue>, property:, prop_key:, as:. The issue's history line of that
    # property as IssuesHelper#show_detail draws it, on the page and as text (the text is also the email's): the line
    # is the registered renderer's and not core's own, so it comes through the register. Nothing written.
    ::GkScenarios::Expect.register('cst_journal_details') do |ctx, e|
      property = e['property'].to_s
      key = e['prop_key']&.to_s
      want = "#{property}#{key ? ": #{key}" : ''} drawn by the registered renderer"
      next({ 'ok' => true, 'want' => want, 'got' => 'core has the register' }) if GkCoreStuff.in_core?(:journal_details)

      issue = ::GkScenarios::Expect.issue_for(ctx, e['cst_journal_details'])
      user = e['as'] ? ::User.find_by(login: ::GkScenarios::Expect.login(ctx, e['as'])) : ::User.active.where(admin: true).order(:id).first
      detail = issue && ::JournalDetail.where(journal_id: issue.journals.select(:id), property: property).then { |s| key ? s.where(prop_key: key) : s }.order(:id).last
      next({ 'ok' => false, 'want' => "a history line #{property} on #{e['cst_journal_details']}", 'got' => '-' }) unless detail && user

      renderer = JournalDetails.renderer_for(detail)
      next({ 'ok' => false, 'want' => want, 'got' => 'nothing registered for it' }) unless renderer

      core = ScenarioRender.core_method(::IssuesHelper, :show_detail)
      out = {}
      ctx.as(user) do
        ::IssuesController.renderer.render(inline: '<% [false, true].each { |t| out[t] = [show_detail(d, t), r.call(d, self, t, {}), core.bind_call(self, d, t)] } %>',
                                           locals: { d: detail, r: renderer, core: core, out: out })
      end
      checks = []
      { false => 'page', true => 'text' }.each do |t, label|
        mine, theirs, core_line = out[t]
        checks << ["#{label}: the renderer's line", mine.to_s == theirs.to_s]
        checks << ["#{label}: not core's own", mine.to_s != core_line.to_s]
      end
      failed = checks.reject(&:last).map(&:first)
      { 'ok' => failed.empty?, 'want' => want, 'got' => failed.empty? ? out[true].first.to_s : "not: #{failed.join(', ')}" }
    end
  end
end
