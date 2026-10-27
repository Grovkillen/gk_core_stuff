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

    def in_core?(name) = !!@modules[name.to_s]&.in_core&.call
    def always?(name) = !!@modules[name.to_s]&.always

    # On: switched on in the settings, or always on, and core does not have it already
    def on?(name) = (always?(name) || settings[name.to_s].to_s == '1') && !in_core?(name)

    def apply_modules!
      @modules.each_value { |m| m.apply.call unless m.in_core.call }
    end
  end
end
