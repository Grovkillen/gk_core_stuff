# frozen_string_literal: true

module GkCoreStuff
  # The module register. A module registers its name, its settings with defaults, a test for whether core already has
  # the thing, asked of compat (core_has?; then it hooks nothing in and says so on the settings page) and how it hooks
  # in. Every module is a
  # setting of its own, on or off for the instance, except a module registered with always: true, which other plugins
  # require: it has no setting and is on for as long as core does not have the thing.
  Mod = Struct.new(:name, :issue, :defaults, :in_core, :always, :apply, keyword_init: true)

  @modules = {}

  class << self
    attr_reader :modules

    # hooks: the view hooks a step module adds, each with the views that call it (core's names, a partial with its
    # underscore: 'issues/show', 'settings/_general'); kept also when core has the step, so that hook? answers then too
    # hook_needs: for a view whose hook a helper method calls, and only when more views than that one come from the
    # module (layout_hooks' title hook, called only when layouts/base and users/edit both carry the step):
    # { hook => { view => [every view that must carry] } }
    def register(name, issue:, defaults:, in_core:, always: false, hooks: {}, hook_needs: {}, &apply)
      @modules[name.to_s] = Mod.new(name: name.to_s, issue: issue, defaults: defaults, in_core: in_core, always: always,
                                    apply: apply)
      hook_views[name.to_s] = hooks.to_h { |h, views| [h.to_sym, Array(views).map(&:to_s).freeze] }.freeze unless hooks.empty?
      unless hook_needs.empty?
        hook_view_needs[name.to_s] = hook_needs.to_h do |h, by_view|
          [h.to_sym, by_view.to_h { |v, needs| [v.to_s, Array(needs).map(&:to_s).freeze] }.freeze]
        end.freeze
      end
    end

    # The view hooks the step modules add, by module name: { hook => [views] } (register's hooks:)
    def hook_views = (@hook_views ||= {})

    # The views that must carry a module's lines before a view counts as calling a hook, by module name (register's
    # hook_needs:); a view not listed needs only itself
    def hook_view_needs = (@hook_view_needs ||= {})

    # The step module that adds a view hook, or nil for a hook no module adds
    def hook_owner(hook)
      h = hook.to_sym
      hook_views.each { |name, map| return name if map.key?(h) }
      nil
    end

    # Public API for other plugins: whether the page drawn now calls the view hook +hook+, so that a plugin draws its
    # part on the hook when it is called and somewhere else only when it is not.
    # * A hook no step module adds is core's own: true. core_stuff does not search core's views for the hooks they
    #   call, so a name core does not know is also true; ask only for a hook core or a step module documents.
    # * A hook a step module adds: true when core has the step (compat's ability of the module's name); otherwise
    #   only when the views that call it are drawn from the module's copies or from a later step's copies built on
    #   them (carrying_dirs), never when a plugin's own copy of the view stands first or the series has no copies.
    # view: one of the views that call the hook ('settings/_general' for view_settings_form_save_after), to ask about
    # that view alone; without it every view of the series that calls the hook must carry it. A view that does not
    # call the hook gives false.
    # Decided by where the views come from, never by their text; asked when a page is drawn and kept once every
    # plugin has registered its views (settle_views!, after initialization).
    def hook?(hook, view: nil)
      h = hook.to_sym
      owner = hook_owner(h)
      return true if owner.nil? || in_core?(owner)
      return false unless on?(owner) && series_dirs[owner]

      key = [h, view&.to_s]
      return hook_answers[key] if views_settled? && hook_answers.key?(key)

      answer = hook_drawn?(owner, h, view&.to_s)
      hook_answers[key] = answer if views_settled?
      answer
    rescue StandardError
      false
    end

    # The views of the running series that call +hook+ of module +owner+ (the module has a copy of them) and whether
    # each is drawn from a folder that carries the module's lines; a view with hook_needs counts only when every view
    # it needs has a copy and is drawn from such a folder
    def hook_drawn?(owner, hook, view)
      views = hook_views[owner][hook]
      views &= [view] if view
      dir = series_dirs[owner]
      present = views.select { |v| File.exist?(File.join(dir, "#{v}.html.erb")) }
      return false if present.empty?

      needs = hook_view_needs.dig(owner, hook) || {}
      present.all? do |v|
        needs.fetch(v, [v]).all? do |n|
          next false unless File.exist?(File.join(dir, "#{n}.html.erb"))

          folder, base = File.split(n)
          partial = base.start_with?('_')
          view_carries?(owner, partial ? File.join(folder, base.delete_prefix('_')) : n, partial: partial)
        end
      end
    end

    def hook_answers = (@hook_answers ||= {})
    def views_settled? = @views_settled == true

    # Called after initialization, when every plugin has registered its views: from now on hook? keeps its answers
    def settle_views!
      hook_answers.clear
      @views_settled = true
    end

    def defaults = @modules.values.each_with_object({}) { |m, h| h.merge!(m.defaults) }

    def settings
      s = ::Setting.plugin_gk_core_stuff
      s.is_a?(Hash) ? defaults.merge(s.transform_keys(&:to_s)) : defaults
    rescue StandardError
      defaults
    end

    # Has core what a module adds? compat answers for the running series, as an ability; without compat, or with one
    # that does not know the ability yet, core has not, and the module hooks in as before
    def core_has?(ability)
      defined?(::GkCompat) && ::GkCompat.can?(ability) ? true : false
    rescue KeyError
      false
    end

    # A module's copies of core's views for the running series (modules/<name>/views/<series>/app/views, made by
    # core_views.ps1), chosen by compat (GkCompat.series_dir; version checks live only there), or nil when there are
    # none for the series or compat lacks series_dir
    def series_views(name)
      return nil unless defined?(::GkCompat) && ::GkCompat.respond_to?(:series_dir)

      dir = ::GkCompat.series_dir(File.expand_path("../../modules/#{name}/views", __dir__))
      dir && File.directory?(File.join(dir, 'app', 'views')) ? File.join(dir, 'app', 'views') : nil
    end

    # Puts the module's views for the running series in the view paths, once: right before core's own app/views, after
    # every plugin's, so that a plugin that overrides one of the views (fields' issues/_form_custom_fields, people's
    # groups/show) keeps its own until it uses the hooks instead; every other view gets the hooks.
    # Without views for the series a warning in the log. Returns the folder, or nil.
    # replaces: the modules whose copies this module's copies are built on (core_views.ps1 applies the earlier steps of
    # a view first, so the later step's copy has their lines too): the folder stands before theirs, whichever module
    # registers first.
    # adds: what the module's copies add to core's views, :hooks (steps 01, 04, 05, 06, 10) or :marks (steps 08 and 09); it picks
    # the words in the log and on the settings page for a view that is missing or that a plugin overrides.
    def prepend_series_views(name, replaces: [], adds: :hooks)
      view_adds[name.to_s] = adds
      view_replaces[name.to_s] = replaces.map(&:to_s)
      hook_answers.clear
      dir = series_views(name)
      if dir.nil?
        lost = adds == :marks ? 'the marks in the views are not on the page' : 'the hooks in the views are not called'
        Rails.logger.warn("[gk_core_stuff] #{name}: no views for the running Redmine series (core_views.ps1, and GK Compat " \
                          "with series_dir); #{lost}")
        return nil
      end
      series_dirs[name.to_s] = dir
      paths = ::ActionController::Base.view_paths.map(&:to_s)
      return dir if paths.include?(dir)

      core = Rails.root.join('app', 'views').to_s
      at = paths.index { |p| File.expand_path(p) == File.expand_path(core) } || paths.size
      replaces.each do |other|
        theirs = series_dirs[other.to_s] && paths.index(series_dirs[other.to_s])
        at = theirs if theirs && theirs < at
      end
      ::ActionController::Base.view_paths = paths.insert(at, dir)
      dir
    end

    # The modules' view folders in use, by module name
    def series_dirs = (@series_dirs ||= {})

    # Which modules' copies each module's copies are built on (prepend_series_views' replaces:), by module name
    def view_replaces = (@view_replaces ||= {})

    # The view folders in use whose copies carry what a module's copies add: the module's own and those of every module
    # built on it, also through another (steps 09 and 10 build layouts/base and issues/show on step 01's lines). A test
    # of where a drawn view comes from asks this, never one module's folder alone.
    def carrying_dirs(name)
      names = [name.to_s]
      loop do
        more = view_replaces.select { |n, built_on| !names.include?(n) && built_on.intersect?(names) }.keys
        break if more.empty?

        names.concat(more)
      end
      names.filter_map { |n| series_dirs[n] }
    end

    # Whether a view drawn now (its template's file) comes from a folder that carries the module's additions
    def view_carries?(name, view, partial: false)
      found = File.expand_path(::ActionController::Base.new.lookup_context.find_template(view, [], partial).identifier.to_s)
      carrying_dirs(name).any? { |d| found.start_with?(File.join(File.expand_path(d), '')) }
    end

    # What each module's views add (prepend_series_views' adds:), by module name; :hooks when not said
    def view_adds = (@view_adds ||= {})
    def marks?(name) = view_adds[name.to_s] == :marks

    # The views of a module that a plugin overrides (its own copy stands before the module's in the view paths). Asked
    # after every plugin has registered its views: plugins after core_stuff in the alphabet (fields, people) register
    # later than core_stuff's own init. Another module's folder before it is no plugin: its copy is built on this
    # module's (prepend_series_views' replaces:) and keeps the hooks.
    def shadowed_views(name)
      dir = series_dirs[name.to_s]
      return [] unless dir

      paths = ::ActionController::Base.view_paths.map(&:to_s)
      at = paths.index(dir)
      return [] unless at

      before = paths.first(at) - series_dirs.values
      Dir.glob(File.join(dir, '**', '*.erb')).map { |f| f.delete_prefix("#{dir}/") }.select do |v|
        before.any? { |p| File.exist?(File.join(p, v)) }
      end
    end

    # One line in the log per module whose views a plugin overrides (called after initialization)
    def log_shadowed_views!
      series_dirs.each_key do |name|
        shadowed = shadowed_views(name)
        next if shadowed.empty?

        Rails.logger.info("[gk_core_stuff] #{name}: a plugin overrides #{shadowed.join(', ')}; its own view is used, " \
                          "without the #{marks?(name) ? 'marks' : 'hooks'}")
      end
    end

    def in_core?(name) = !!@modules[name.to_s]&.in_core&.call
    def always?(name) = !!@modules[name.to_s]&.always

    # On: switched on in the settings, or always on, and core does not have it already
    def on?(name) = (always?(name) || settings[name.to_s].to_s == '1') && !in_core?(name)

    # GK Records' register of appearance settings, nil without records (then every look and the three modules that
    # change how core's pages read are off)
    def appearance_settings = defined?(::GkRecords::AppearanceSettings) ? ::GkRecords::AppearanceSettings : nil

    # One of the three modules that are appearance settings with only off and forced (done_ratio_text, time_ampm_nbsp,
    # footer_version): on for everyone when forced, and core does not have it already
    def appearance_on?(name)
      r = appearance_settings
      r ? r.mode("core_stuff.#{name}") != 'off' && !in_core?(name) : false
    end

    def appearance_value(name, value_name)
      r = appearance_settings
      r&.value("core_stuff.#{name}", value_name)
    end

    def apply_modules!
      @modules.each_value { |m| m.apply.call unless m.in_core.call }
    end
  end
end
