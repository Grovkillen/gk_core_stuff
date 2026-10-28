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

    def register(name, issue:, defaults:, in_core:, always: false, &apply)
      @modules[name.to_s] = Mod.new(name: name.to_s, issue: issue, defaults: defaults, in_core: in_core, always: always,
                                    apply: apply)
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
    def prepend_series_views(name)
      dir = series_views(name)
      if dir.nil?
        Rails.logger.warn("[gk_core_stuff] #{name}: no views for the running Redmine series (core_views.ps1, and GK Compat " \
                          'with series_dir); the hooks in the views are not called')
        return nil
      end
      series_dirs[name.to_s] = dir
      paths = ::ActionController::Base.view_paths.map(&:to_s)
      return dir if paths.include?(dir)

      core = Rails.root.join('app', 'views').to_s
      at = paths.index { |p| File.expand_path(p) == File.expand_path(core) } || paths.size
      ::ActionController::Base.view_paths = paths.insert(at, dir)
      dir
    end

    # The modules' view folders in use, by module name
    def series_dirs = (@series_dirs ||= {})

    # The views of a module that a plugin overrides (its own copy stands before the module's in the view paths). Asked
    # after every plugin has registered its views: plugins after core_stuff in the alphabet (fields, people) register
    # later than core_stuff's own init.
    def shadowed_views(name)
      dir = series_dirs[name.to_s]
      return [] unless dir

      paths = ::ActionController::Base.view_paths.map(&:to_s)
      at = paths.index(dir)
      return [] unless at

      Dir.glob(File.join(dir, '**', '*.erb')).map { |f| f.delete_prefix("#{dir}/") }.select do |v|
        paths.first(at).any? { |p| File.exist?(File.join(p, v)) }
      end
    end

    # One line in the log per module whose views a plugin overrides (called after initialization)
    def log_shadowed_views!
      series_dirs.each_key do |name|
        shadowed = shadowed_views(name)
        Rails.logger.info("[gk_core_stuff] #{name}: a plugin overrides #{shadowed.join(', ')}; its own view is used, without the hooks") if shadowed.any?
      end
    end

    def in_core?(name) = !!@modules[name.to_s]&.in_core&.call
    def always?(name) = !!@modules[name.to_s]&.always

    # On: switched on in the settings, or always on, and core does not have it already
    def on?(name) = (always?(name) || settings[name.to_s].to_s == '1') && !in_core?(name)

    def apply_modules!
      @modules.each_value { |m| m.apply.call unless m.in_core.call }
    end
  end
end
