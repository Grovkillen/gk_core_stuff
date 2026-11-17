# frozen_string_literal: true

module GkCoreStuff
  # The modules that fix how core's own pages look or read (a lift of 4 px, a height, a width, core's own word), each
  # written as a core candidate in modules/<name>/patch. Until core has the fix, the module hooks it in from the page's
  # head: a stylesheet, a script, or both, only for the one the module is on for.
  # Each look is an appearance setting in GK Records' register (core_stuff.<key>, set under Administration, Appearance in
  # GK GUI Stuff): off (a new installation), optional (on, and each person may switch it off under My account,
  # Appearance) or forced (on for everyone). The register keeps the levels and a person's own choices; without records
  # every look is off. A look core already has (in_core) is drawn as core's and never hooked in.
  # stylesheet: true and script: true: the module's own file in assets/ (script: a name, a file two looks share); a
  # script also loads the shared kernel (gk_core_stuff_looks.js: one content observer, the texts and values the server
  # sent). texts: locale keys the script needs. options: a lambda giving the module's values to the script. anonymous: also on for someone not
  # logged in (only the instance's level counts then). values: the values under the look's row in the register, in
  # the register's form ({ name => { kind:, default:, label:, info: } }), declared with the row.
  module Looks
    Look = Struct.new(:key, :stylesheet, :script, :texts, :options, :anonymous, :group, :proposal, :values, keyword_init: true)
    MODES = %w[off optional forced].freeze

    # The group on the page Appearance and GK's proposal per look; a look not named here is in Lists and off in the
    # proposal
    GROUPS = {
      'instance' => %w[sidebar_spacing menu_icons dark_mode chart_colors],
      'lists' => %w[list_badge list_checkbox list_align list_hash ajax_indicator block_icons],
      'issue' => %w[heading_badge],
      'forms' => %w[warning_balance label_rows field_widths settings_widths control_heights native_texts submit_word list_sort],
      'text' => %w[external_links],
      'admin' => %w[scm_table]
    }.freeze
    FORCED = %w[list_badge heading_badge list_checkbox list_align warning_balance label_rows sidebar_spacing field_widths
                settings_widths control_heights native_texts external_links scm_table].freeze
    RELATED = {
      'list_badge' => %w[core_stuff.heading_badge gui_stuff.filled_badges], 'heading_badge' => %w[core_stuff.list_badge gui_stuff.filled_badges],
      'field_widths' => %w[core_stuff.settings_widths], 'settings_widths' => %w[core_stuff.field_widths],
      'external_links' => %w[gui_stuff.mailto_copy], 'list_sort' => %w[gui_stuff.list_filter], 'menu_icons' => %w[gui_stuff.custom_mark],
      'sidebar_spacing' => %w[tags.sidebar]
    }.freeze
    # The looks that show no picture under Visa: three steps each, text_gk_core_stuff_step_<key>_1 to _3
    STEPS = %w[list_sort].freeze
    # The looks Visa shows off and on, drawn the way the style guide draws core: gk_core_stuff_appearance/previews/_<key>
    PREVIEWS = %w[list_badge heading_badge list_checkbox label_rows].freeze
    # What a look changes on the pages, as data for records' register (footprint: and applies:, GkRecords::Footprint),
    # read from the look's own stylesheet or script; only core's purposeful classes and ids, GK's own classes and the
    # effect mark data-gk-core-stuff-effect that a look's own code sets on what it changed. A look not named here shows
    # "not described yet" on the page Appearance. Each look's stylesheet and script is loaded only while it is on
    # (applies script). An effect mark or a class the look sets itself exists only while the look is on, so such a look
    # counts no places on the first page after it is switched off.
    # Where core offers nothing finer, the anchor names the part of the page the look works in: sidebar_spacing the
    # sidebar, label_rows a tabular form, ajax_indicator a list, footer_version the footer; dark_mode the whole page,
    # named by core's page and content. chart_colors names only the effect mark it sets on each chart and graph it
    # changed, so that a page where nothing changed (the light without a theme) counts no place.
    FOOTPRINTS = {
      'dark_mode' => { applies: %w[script], footprint: { anchors: ['#wrapper', '#content'], elements: %w[core_tables core_forms core_badges core_context_menu], pages: %w[all] } },
      'chart_colors' => { applies: %w[script], footprint: { anchors: ['[data-gk-core-stuff-effect~="chart_colors"]'] } },
      'sidebar_spacing' => { applies: %w[script], footprint: { anchors: ['#sidebar'] } },
      'menu_icons' => { applies: %w[script], footprint: { anchors: ['#context-menu a.icon'], elements: %w[core_context_menu] } },
      'footer_version' => { applies: %w[server], footprint: { anchors: ['#footer'], pages: %w[all] } },
      'list_badge' => { applies: %w[script], footprint: { anchors: ['table.list .badge'], elements: %w[core_badges core_tables] } },
      'list_checkbox' => { applies: %w[script], footprint: { anchors: ['table.list td.checkbox'], elements: %w[core_tables] } },
      'list_hash' => { applies: %w[script], footprint: { anchors: ['table.list tr.issue'], elements: %w[core_tables] } },
      'block_icons' => { applies: %w[script], footprint: { anchors: ['.icon-sort-handle'] } },
      'list_align' => { applies: %w[script], footprint: { anchors: ['[data-gk-core-stuff-effect~="list_align"]'], elements: %w[core_tables] } },
      'ajax_indicator' => { applies: %w[script], footprint: { anchors: ['table.list'], elements: %w[core_tables] } },
      'done_ratio_text' => { applies: %w[server], footprint: { anchors: ['[data-gk-core-stuff-effect~="done_ratio_text"]'], elements: %w[core_tables] } },
      'time_ampm_nbsp' => { applies: %w[server], footprint: { pages: %w[all] } },
      'heading_badge' => { applies: %w[script], footprint: { anchors: ['[data-gk-core-stuff-effect~="heading_badge"]', '.badge.gk-heading-badge'], elements: %w[core_badges] } },
      'label_rows' => { applies: %w[script], footprint: { anchors: ['.tabular'], elements: %w[core_forms] } },
      'warning_balance' => { applies: %w[script], footprint: { anchors: ['.nodata', '.warning'] } },
      'field_widths' => { applies: %w[script], footprint: { anchors: ['[data-gk-core-stuff-effect~="field_widths"]'], elements: %w[core_forms] } },
      'settings_widths' => { applies: %w[script], footprint: { anchors: ['[data-gk-core-stuff-effect~="settings_widths"]'], elements: %w[core_forms] } },
      'control_heights' => { applies: %w[script], footprint: { anchors: ['[data-gk-core-stuff-effect~="control_heights"]'], elements: %w[core_forms core_buttons] } },
      'submit_word' => { applies: %w[script], footprint: { anchors: ['[data-gk-core-stuff-effect~="submit_word"]'], elements: %w[core_buttons] } },
      'native_texts' => { applies: %w[script], footprint: { anchors: ['[data-gk-core-stuff-effect~="native_texts"]', '.gk-core-stuff-file'], elements: %w[core_forms] } },
      'list_sort' => { applies: %w[script], footprint: { anchors: ['[data-gk-core-stuff-sorted]', '[data-gk-sort]'], elements: %w[core_forms] } },
      'external_links' => { applies: %w[script], footprint: { anchors: ['.gk-link-external'] } },
      'scm_table' => { applies: %w[script], footprint: { anchors: ['th.scm_version', 'td.scm_name'], elements: %w[core_tables] } }
    }.freeze
    # The looks with no element to point at, and why: their footprint says where they work without an anchor, and their
    # help text says that no place is counted for them
    NO_PLACE = {
      'time_ampm_nbsp' => 'a number format: a no-break space inside the text of a time, which core draws as plain text with no element of its own'
    }.freeze
    # The modules that are appearance settings without being looks (declared on their own in declare_appearances!)
    MODULE_ROWS = %w[done_ratio_text time_ampm_nbsp footer_version].freeze

    @all = {}

    class << self
      def all = @all

      def find(key) = @all[key.to_s]
      def row_key(key) = "core_stuff.#{key}"
      def group_of(key) = GROUPS.find { |_g, keys| keys.include?(key.to_s) }&.first || 'lists'

      # A look is also a module of the register, so that in_core? sees it; its level is its appearance setting
      def register(key, stylesheet: false, script: false, texts: [], options: nil, anonymous: false, values: {}, in_core: -> { false })
        k = key.to_s
        @all[k] = Look.new(key: k, stylesheet: stylesheet ? "gk_core_stuff_#{k}" : nil, script: script == true ? "gk_core_stuff_#{k}" : (script || nil),
                           texts: texts, options: options, anonymous: anonymous, group: group_of(k), proposal: FORCED.include?(k) ? 'forced' : 'off',
                           values: values || {})
        GkCoreStuff.register(k, issue: nil, defaults: {}, in_core: in_core) { nil }
      end

      # The administrator's level for the instance, off without records
      def mode(key) = (r = GkCoreStuff.appearance_settings) ? r.mode(row_key(key)) : 'off'

      def optional = @all.values.select { |l| available?(l) && mode(l.key) == 'optional' }

      def available?(look) = !GkCoreStuff.in_core?(look.key)

      def on_for?(key, user = User.current)
        look = find(key)
        return false unless look && available?(look)

        r = GkCoreStuff.appearance_settings
        r ? r.on_for?(row_key(look.key), user) : false
      end

      def active(user = User.current) = @all.values.select { |l| on_for?(l.key, user) }

      # Every look, and the three modules that change how core's pages read (the done ratio as text, the no-break space
      # before AM and PM, Redmine's version in the footer), in records' register; called once every plugin has loaded
      # (records loads after core_stuff) and again after a reload
      def declare_appearances!
        r = GkCoreStuff.appearance_settings
        return unless r

        @all.each_value do |l|
          k = l.key
          r.register(row_key(k), plugin: :gk_core_stuff, group: l.group, proposal: l.proposal, anonymous: l.anonymous,
                                 label: :"label_gk_core_stuff_#{k}", help: :"text_gk_core_stuff_#{k}_info", related: Array(RELATED[k]),
                                 steps: STEPS.include?(k) ? (1..3).map { |i| :"text_gk_core_stuff_step_#{k}_#{i}" } : nil,
                                 preview: PREVIEWS.include?(k) ? "gk_core_stuff_appearance/previews/#{k}" : nil,
                                 values: l.values || {}, in_core: -> { GkCoreStuff.in_core?(k) }, **footprint_for(k, r))
        end
        two = %w[off forced]
        r.register(row_key('done_ratio_text'), plugin: :gk_core_stuff, group: :lists, modes: two, related: %w[gui_stuff.quick_done],
                                               label: :label_gk_core_stuff_done_ratio_text, help: :text_gk_core_stuff_done_ratio_text_info,
                                               in_core: -> { GkCoreStuff.in_core?(:done_ratio_text) },
                                               values: DoneRatioText.appearance_values, **footprint_for('done_ratio_text', r))
        r.register(row_key('time_ampm_nbsp'), plugin: :gk_core_stuff, group: :lists, modes: two,
                                              label: :label_gk_core_stuff_time_ampm_nbsp, help: :text_gk_core_stuff_time_ampm_nbsp_info,
                                              in_core: -> { GkCoreStuff.in_core?(:time_ampm_nbsp) }, **footprint_for('time_ampm_nbsp', r))
        r.register(row_key('footer_version'), plugin: :gk_core_stuff, group: :instance, modes: two, anonymous: true,
                                              related: %w[gui_stuff.footer_text], label: :label_gk_core_stuff_footer_version,
                                              help: :text_gk_core_stuff_footer_version_info, in_core: -> { GkCoreStuff.in_core?(:footer_version) },
                                              **footprint_for('footer_version', r))
      rescue StandardError => e
        Rails.logger.warn("[gk_core_stuff] appearance settings not declared: #{e.class} #{e.message}")
      end

      # A look's footprint and applies (FOOTPRINTS), given only to a register that takes them (an older register lacks
      # the keywords); {} for a look not described
      def footprint_for(key, register)
        h = FOOTPRINTS[key.to_s]
        return {} unless h

        names = register.method(:register).parameters.map(&:last)
        names.include?(:footprint) && names.include?(:applies) ? { footprint: h[:footprint], applies: h[:applies] } : {}
      end

      # The head's tags: each look's stylesheet, and for the scripts the config, the kernel and the scripts
      def head_tags(view)
        looks = active
        return ''.html_safe if looks.empty?

        tags = looks.filter_map(&:stylesheet).map { |s| view.stylesheet_link_tag(s, plugin: 'gk_core_stuff') }
        scripts = looks.select(&:script)
        if scripts.any?
          cfg = { looks: scripts.map(&:key),
                  t: scripts.flat_map(&:texts).uniq.to_h { |k| [k.to_s.sub('gk_core_stuff_', ''), ::I18n.t(k)] },
                  opt: scripts.select(&:options).to_h { |l| [l.key, l.options.call] } }
          tags << view.content_tag(:script, ::ERB::Util.json_escape(cfg.to_json).html_safe, type: 'application/json', id: 'gk-core-stuff-looks')
          tags << view.javascript_include_tag('gk_core_stuff_looks', plugin: 'gk_core_stuff')
          tags.concat(scripts.map(&:script).uniq.map { |s| view.javascript_include_tag(s, plugin: 'gk_core_stuff') })
        end
        view.safe_join(tags, "\n")
      end
    end
  end
end
