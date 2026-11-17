# frozen_string_literal: true

module GkCoreStuff
  # The gate to GK GUI Stuff and GK Compat, which core_stuff requires both. An older GK GUI Stuff or GK Compat than the
  # lowest base version does not open the gate, and neither does a GK GUI Stuff whose own gate is closed. Base versions
  # are compared (Z.YY.XXX without a candidate's suffix), so a candidate of the required version opens the gate.
  #
  # A gate closes only the interface, never a protection. Closed, the gate closes what a person works with and what
  # core_stuff draws on core's pages: no module hooks in but the two below (no other core patch, no copies of core's
  # views, so no hooks and no marks in them), no look and no stylesheet in the page's head, no line in the footer, no
  # hook of the view listener, no appearance setting in another plugin's register, no scenarios, and no DSL for the
  # tabs and the history lines. It never closes:
  # * the filter of values in the log (Gate::FILTERED): PIN codes, one-time tokens and a person's identifier are
  #   filtered from every request's parameters whatever the gate says. It reads nothing of GK GUI Stuff or GK Compat;
  # * the list of core's exports (exports.rb): data about core's own actions, which draws nothing. The plugin that
  #   logs exports reads it, so the trace of an export of one of core's lists is written also with the gate closed;
  # * the pass over formatted text and over a custom field's formatted value (the modules formatting_processors and
  #   formatting_processors_values, hooked in by Patches.protect!): other plugins hook what they must always write on
  #   a link into it (rel on a link to another site). The pass draws nothing itself; with no processor registered the
  #   text is not even parsed. What a processor adds is the registering plugin's own, behind that plugin's own gate.
  # core_stuff has no permissions and no project modules to keep.
  # The settings page says why in one line of core's own form (<p class="warning">) per plugin, the first thing that
  # is not met: the plugin is missing, it is too old (with the version required), or GK GUI Stuff is there in the
  # right version but not active, and that protection and traces hold all the same; beside the About box. The
  # migrations run all the same.
  # The extension and module files are still loaded, so another plugin that asks defined?(::GkCoreStuff::X) finds the
  # registers and is answered as if nothing were hooked in (hook? answers false); the DSL
  # on Redmine::Plugin is not there (Tabs::PluginDsl and JournalDetails::PluginDsl are defined only when the gate
  # opens), so a plugin that asks for it first leaves its tab or history line to core. That plugin must not log the
  # missing name as "gk_core_stuff is missing": core_stuff may be installed with only its gate closed, and a closed
  # gate writes no fallback line to the log; the caller stays silent or asks its own gate first.
  # GK GUI Stuff loads after core_stuff, so it is asked only in methods, never while this file is read. GK Compat may
  # be missing: what is kept outside the gate never needs it (core_has? answers false without it, and for one that
  # cannot answer).

  #   GkCoreStuff.base(version) -> the base version (Z.YY.XXX without a candidate's suffix) as a Gem::Version; nil when
  #   the string is not a version
  def self.base(version)
    b = version.to_s[/\A(\d+\.\d+\.\d+)(?:-.*)?\z/, 1]
    b && ::Gem::Version.new(b)
  end

  # The lowest base version the gate opens for; IDENTITY.yml requires the same base and a test holds the two together
  GUI_STUFF_MIN = '1.05.000'

  #   GkCoreStuff.gui_closed -> nil when the gate is open; otherwise the first thing that is not met: :missing (no GK GUI
  #   Stuff), :old (it does not answer open?, or its base version is older than GUI_STUFF_MIN) or :inactive (its own
  #   gate is closed)
  def self.gui_closed
    return :missing unless defined?(::GkGuiStuff)
    return :old unless ::GkGuiStuff.respond_to?(:open?) && ::GkGuiStuff.respond_to?(:version_at_least?) &&
                       ::GkGuiStuff.version_at_least?(GUI_STUFF_MIN)
    return :inactive unless ::GkGuiStuff.open?

    nil
  rescue StandardError
    :missing
  end

  #   GkCoreStuff.gui? -> true when gui_closed has nothing to say
  def self.gui? = gui_closed.nil?

  # The lowest base version the gate opens for; IDENTITY.yml requires the same base and a test holds the two together
  COMPAT_MIN = '1.03.000'

  #   GkCoreStuff.compat_closed -> nil when GK Compat is there, answers series_dir and its base version is COMPAT_MIN or
  #   later; otherwise the first thing that is not met: :missing or :old (a GK Compat without series_dir is too old)
  def self.compat_closed
    return :missing unless ::Redmine::Plugin.installed?(:gk_compat) && defined?(::GkCompat)
    return :old unless ::GkCompat.respond_to?(:series_dir)

    have = base(::Redmine::Plugin.find(:gk_compat).version)
    have && have >= base(COMPAT_MIN) ? nil : :old
  rescue StandardError
    :missing
  end

  #   GkCoreStuff.compat? -> true when compat_closed has nothing to say
  def self.compat? = compat_closed.nil?

  #   GkCoreStuff.open? -> both: the gate the interface of core_stuff asks (never the log filter, the list of core's
  #   exports or Patches.protect!)
  def self.open? = gui? && compat?

  module Gate
    # The hook methods a view or controller listener answers (view_*, controller_*, model_*). Redmine asks a listener
    # respond_to?(hook) once and keeps the answer (Redmine::Hook.hook_listeners), so a closed gate (without GK GUI
    # Stuff or GK Compat) keeps every hook of core_stuff's listeners silent. A listener is registered as soon
    # as its class is defined (Listener.inherited), so the gate is in the listener and not in init.rb.
    HOOK = /\A(view|controller|model)_/

    module Listener
      def respond_to?(name, include_all = false)
        return false if HOOK.match?(name.to_s) && !GkCoreStuff.open?

        super
      end
    end

    # Values that never belong in the log (people's PIN codes, one-time tokens, a person's identifier such as a personal
    # identity number), filtered from every request's parameters as Redmine filters passwords. The patterns are
    # anchored, so a project's identifier or an authenticity_token stays as it is. A protection: set also with the gate
    # closed (start!).
    FILTERED = [/\A(pin|pin_again|new_pin|new_pin_again)\z/, /\Atoken\z/, 'identifier.value'].freeze

    module_function

    # core_stuff at work, once GK GUI Stuff and GK Compat are known: core_stuff loads before gk_gui_stuff (Redmine loads
    # the plugins in the order of their directories' names), so its init.rb cannot ask the gate. Boot below
    # calls this at the end of every preparation, the first and each reload in development, when every plugin's init.rb has run and before any
    # after_initialize block (where the other plugins add their tabs and history lines). Whatever the gate says: the
    # log filter (once) and the pass over formatted text (Patches.protect!). Only with the gate open: the names other
    # plugins ask for the DSL, and every module hooked in (each prepend guarded against a second one, Patches.apply!),
    # the DSL on Redmine::Plugin with them. Returns whether the gate is open.
    def start!
      filters!
      Patches.protect!
      return false unless GkCoreStuff.open?

      dsl!
      Patches.apply!
      true
    end

    # The names other plugins ask before they use the tabs' and the history lines' DSL (defined?(...::PluginDsl)): given
    # also when core has the register, so that their same line reaches core's DSL then
    def dsl!
      { Tabs => Tabs::Dsl, JournalDetails => JournalDetails::Dsl }.each do |owner, dsl|
        owner.const_set(:PluginDsl, dsl) unless owner.const_defined?(:PluginDsl, false)
      end
    end

    def filters!
      list = ::Rails.application.config.filter_parameters
      FILTERED.each { |f| list << f unless list.include?(f) }
    end

    # Core's hook at the end of each preparation (Redmine::PluginLoader, after every plugin's init.rb); not a view
    # hook, so the listener's gate above leaves it alone
    class Boot < ::Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        Gate.start!
      end
    end
  end
end
