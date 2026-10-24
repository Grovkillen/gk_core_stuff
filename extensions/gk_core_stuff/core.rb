# frozen_string_literal: true

module GkCoreStuff
  # The module register. A module registers its name, its settings with defaults, a test for whether core already has
  # the thing (then it hooks nothing in and says so on the settings page) and how it hooks in. Every module is a
  # setting of its own, on or off for the instance.
  Mod = Struct.new(:name, :issue, :defaults, :in_core, :apply, keyword_init: true)

  @modules = {}

  class << self
    attr_reader :modules

    def register(name, issue:, defaults:, in_core:, &apply)
      @modules[name.to_s] = Mod.new(name: name.to_s, issue: issue, defaults: defaults, in_core: in_core, apply: apply)
    end

    def defaults = @modules.values.each_with_object({}) { |m, h| h.merge!(m.defaults) }

    def settings
      s = ::Setting.plugin_gk_core_stuff
      s.is_a?(Hash) ? defaults.merge(s.transform_keys(&:to_s)) : defaults
    rescue StandardError
      defaults
    end

    def in_core?(name) = !!@modules[name.to_s]&.in_core&.call

    # On: switched on in the settings and core does not have it already
    def on?(name) = settings[name.to_s].to_s == '1' && !in_core?(name)

    def apply_modules!
      @modules.each_value { |m| m.apply.call unless m.in_core.call }
    end
  end
end
