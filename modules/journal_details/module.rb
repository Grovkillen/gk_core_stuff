# frozen_string_literal: true

module GkCoreStuff
  # journal_details. Core draws the lines of an issue's history (and of the email and the text) in
  # IssuesHelper#show_detail, which knows only core's own properties, so a plugin that writes its own journal details
  # overrides the helper, and several plugins chain over it. The upstream form is the proposal view_hooks
  # (redmine/core_proposals/view_hooks): the register Redmine::JournalDetails and the plugin DSL journal_detail. Here
  # the same register is GkCoreStuff::JournalDetails with the same methods, hooked in with prepend, and the same DSL on
  # Redmine::Plugin while core has none. One addition beyond the proposal: a prop_key may be a Regexp. A plugin
  # registers after all plugins are loaded (core_stuff loads after plugins earlier in the alphabet), through its own
  # Redmine::Plugin object, so the same line works with core's DSL the day core has it:
  #   Rails.configuration.after_initialize do
  #     Redmine::Plugin.find(:gk_a).journal_detail property: 'gk_a', renderer: GkA::JournalDetail
  #   end
  # The renderer of a journal detail property: responds to call(detail, view, no_html, options) and returns the line
  # as HTML, or as text when no_html (the text is also used in emails). One registered with a prop_key comes first.
  # A prop_key may also be a Regexp, for a plugin whose keys carry an id (gk_triggers_log_<id>): it answers for every
  # key it matches, after an exact key and before the whole property, in the order the patterns were registered.
  module JournalDetails
    @renderers = {}
    @patterns = []

    class << self
      def register(property, renderer, prop_key: nil)
        raise ArgumentError, "Invalid renderer for journal detail property '#{property}'" unless renderer.respond_to?(:call)

        if prop_key.is_a?(Regexp)
          @patterns.reject! { |p, k, _| p == property.to_s && k == prop_key }
          @patterns << [property.to_s, prop_key, renderer]
        else
          @renderers[[property.to_s, prop_key&.to_s]] = renderer
        end
      end

      def renderer_for(detail)
        property = detail.property.to_s
        key = detail.prop_key.to_s
        @renderers[[property, key]] || @patterns.detect { |p, k, _| p == property && k.match?(key) }&.last || @renderers[[property, nil]]
      end

      # What is registered, for the settings page: the property, and the key or the pattern when there is one
      def registered
        @renderers.keys.map { |p, k| k ? "#{p}: #{k}" : p } + @patterns.map { |p, k, _| "#{p}: #{k.inspect}" }
      end

      def clear
        @renderers.clear
        @patterns.clear
      end

      def on? = GkCoreStuff.on?(:journal_details)
    end

    module IssuesHelperPatch
      def show_detail(detail, no_html = false, options = {})
        renderer = JournalDetails.on? && JournalDetails.renderer_for(detail)
        return renderer.call(detail, self, no_html, options) if renderer

        super
      end
    end

    # The journal details part of the proposal's DSL on Redmine::Plugin, for as long as core has none
    module PluginDsl
      def journal_detail(property:, renderer:, prop_key: nil)
        GkCoreStuff::JournalDetails.register(property, renderer, prop_key: prop_key)
      end
    end
  end

  # Always on, without a setting: other plugins require the register for their history lines, and the register
  # changes nothing until a plugin adds to it
  register :journal_details, issue: 44660, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:journal_details) }, always: true do
    ::Redmine::Plugin.include(JournalDetails::PluginDsl) unless ::Redmine::Plugin.include?(JournalDetails::PluginDsl)
    ::IssuesHelper.prepend(JournalDetails::IssuesHelperPatch) unless ::IssuesHelper < JournalDetails::IssuesHelperPatch
  end
end
