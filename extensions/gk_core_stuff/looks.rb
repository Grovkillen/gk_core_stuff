# frozen_string_literal: true

module GkCoreStuff
  # The modules that fix how core's own pages look or read (a lift of 4 px, a height, a width, core's own word), each
  # written as a core candidate in modules/<name>/patch. Until core has the fix, the module hooks it in from the page's
  # head: a stylesheet, a script, or both, only for the one the module is on for.
  # Three levels per module, set on the plugin's settings page: off, optional (on, and each person may switch it off
  # under My account, Preferences) and forced (on for everyone). What a person switched off is kept in their
  # preferences under gk_core_stuff_looks_off; the first migration's down takes it away when the plugin is
  # uninstalled.
  # stylesheet: true and script: true: the module's own file in assets/ (script: a name, a file two looks share); a
  # script also loads the shared kernel (gk_core_stuff_looks.js: one content observer, the texts and values the server
  # sent). texts: locale keys the script needs. options: a lambda giving the module's values to the script. anonymous: also on for someone not
  # logged in (only the instance's level counts then).
  module Looks
    Look = Struct.new(:key, :default, :stylesheet, :script, :texts, :options, :anonymous, :recommended, keyword_init: true)
    MODES = %w[off optional forced].freeze
    PREF = :gk_core_stuff_looks_off

    @all = {}

    class << self
      def all = @all

      def find(key) = @all[key.to_s]

      # A look is also a module of the register (its level as its setting), so the settings page and in_core? see it
      def register(key, default: 'optional', stylesheet: false, script: false, texts: [], options: nil, anonymous: false, recommended: 'optional', in_core: -> { false })
        k = key.to_s
        @all[k] = Look.new(key: k, default: default, stylesheet: stylesheet ? "gk_core_stuff_#{k}" : nil, script: script == true ? "gk_core_stuff_#{k}" : (script || nil),
                           texts: texts, options: options, anonymous: anonymous, recommended: recommended)
        GkCoreStuff.register(k, issue: nil, defaults: { "look_#{k}" => default }, in_core: in_core) { nil }
      end

      # The administrator's level for the instance; a value from before (1 or 0) reads as optional or off
      def mode(key)
        v = GkCoreStuff.settings["look_#{key}"].to_s
        return v if MODES.include?(v)
        return 'optional' if v == '1'
        return 'off' if v == '0'

        find(key)&.default || 'off'
      end

      def optional = @all.values.select { |l| available?(l) && mode(l.key) == 'optional' }

      def available?(look) = !GkCoreStuff.in_core?(look.key)

      def user_off(user)
        return [] unless user&.logged?

        Array(user.pref[PREF]).map(&:to_s)
      end

      def on_for?(key, user = User.current)
        look = find(key)
        return false unless look && available?(look)

        m = mode(look.key)
        return false if m == 'off'
        return look.anonymous if user.nil? || !user.logged?

        m == 'forced' || !user_off(user).include?(look.key)
      end

      def active(user = User.current) = @all.values.select { |l| on_for?(l.key, user) }

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

    # The person's own choice, a safe attribute of core's preferences: { key => '1' or '0' } from My account; only the
    # optional looks shown there are read, the rest of what was kept stays as it is
    module PreferencePatch
      def gk_core_stuff_looks
        off = Array(self[PREF]).map(&:to_s)
        Looks.optional.to_h { |l| [l.key, off.include?(l.key) ? '0' : '1'] }
      end

      def gk_core_stuff_looks=(values)
        values = values.to_unsafe_h if values.respond_to?(:to_unsafe_h)
        return unless values.is_a?(Hash)

        shown = Looks.optional.map(&:key)
        off = Array(self[PREF]).map(&:to_s) - shown
        values.each { |k, v| off << k.to_s if shown.include?(k.to_s) && v.to_s == '0' }
        self[PREF] = off.uniq.sort
      end
    end

    def self.apply!
      ::UserPreference.prepend(PreferencePatch) unless ::UserPreference < PreferencePatch
      return if ::UserPreference.safe_attributes.any? { |attrs, _| attrs.map(&:to_s).include?('gk_core_stuff_looks') }

      ::UserPreference.safe_attributes('gk_core_stuff_looks')
    end
  end
end
