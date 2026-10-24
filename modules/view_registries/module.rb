# frozen_string_literal: true

module GkCoreStuff
  # view_registries. Core has no register for the tabs of its settings pages or for the lines of an issue's history,
  # so a plugin overrides ProjectsHelper#project_settings_tabs or IssuesHelper#show_detail, and several plugins chain
  # over the same helper. The upstream form is the proposal view_hooks (redmine/core_proposals/view_hooks): the
  # registers Redmine::Tabs and Redmine::JournalDetails and the plugin DSL project_settings_tab,
  # administration_settings_tab, user_settings_tab, group_settings_tab, issue_history_tab and journal_detail.
  # Here the same registers are GkCoreStuff::Tabs and GkCoreStuff::JournalDetails with the same methods, hooked in
  # with prepend, and the same DSL on Redmine::Plugin while core has none. A plugin registers after all plugins are
  # loaded (core_stuff loads after plugins earlier in the alphabet), through its own Redmine::Plugin object, so the
  # same lines work with core's DSL the day core has it:
  #   Rails.configuration.after_initialize do
  #     Redmine::Plugin.find(:gk_a).project_settings_tab :a, partial: 'gk_a/settings', permission: :manage_a
  #     Redmine::Plugin.find(:gk_a).journal_detail property: 'gk_a', renderer: GkA::JournalDetail
  #   end
  module Tabs
    PAGES = %i[project_settings administration_settings user group issue_history].freeze

    @registered = Hash.new { |h, k| h[k] = [] }

    class << self
      def register(page, name, options = {})
        page = page.to_sym
        raise ArgumentError, "Unknown tabs page '#{page}'" unless PAGES.include?(page)
        raise ArgumentError, "Missing :partial for tab '#{name}'" if options[:partial].blank? && !options[:remote]
        raise ArgumentError, "Invalid option :if for tab '#{name}'" if options[:if] && !options[:if].respond_to?(:call)

        @registered[page].reject! { |tab| tab[:name] == name.to_s }
        @registered[page] << options.merge(name: name.to_s)
      end

      def registered(page) = @registered[page.to_sym].dup
      def clear(page = nil) = page ? @registered.delete(page.to_sym) : @registered.clear

      # The tabs with the registered ones at their place. Core's project_settings_tabs filters its list by
      # permission and module before it returns it, so the registered tabs are filtered here (filter: true).
      def add_to(page, tabs, context = {}, filter: false)
        tabs = tabs.dup
        registered(page).each do |options|
          next if options[:if] && !options[:if].call(context)

          tab = { name: options[:name], label: options[:label] || :"label_#{options[:name]}" }
          tab[:partial] = options[:partial] if options[:partial]
          tab[:action] = options[:permission] if options[:permission]
          tab[:module] = options[:module] if options[:module]
          %i[url remote onclick].each { |k| tab[k] = options[k] if options.key?(k) }
          next if filter && !allowed?(tab, context[:project])

          insert(tabs, tab, options)
        end
        tabs
      end

      def on? = GkCoreStuff.on?(:view_registries)

      private

      # A project settings tab without a permission needs :edit_project, as the project tab does (as in the proposal)
      def allowed?(tab, project)
        return false unless ::User.current.allowed_to?(tab[:action] || :edit_project, project)

        tab[:module].nil? || project&.module_enabled?(tab[:module])
      end

      def insert(tabs, tab, options)
        anchor = options[:after] || options[:before]
        index = anchor && tabs.index { |t| t[:name].to_s == anchor.to_s }
        if index.nil? then tabs << tab
        elsif options[:after] then tabs.insert(index + 1, tab)
        else tabs.insert(index, tab)
        end
      end
    end

    module ProjectsHelperPatch
      def project_settings_tabs
        tabs = super
        Tabs.on? ? Tabs.add_to(:project_settings, tabs, { project: @project }, filter: true) : tabs
      end
    end

    module SettingsHelperPatch
      def administration_settings_tabs
        Tabs.on? ? Tabs.add_to(:administration_settings, super) : super
      end
    end

    module UsersHelperPatch
      def user_settings_tabs
        Tabs.on? ? Tabs.add_to(:user, super, { user: @user }) : super
      end
    end

    module GroupsHelperPatch
      def group_settings_tabs(group)
        Tabs.on? ? Tabs.add_to(:group, super, { group: group }) : super
      end
    end

    module IssuesHelperPatch
      def issue_history_tabs
        Tabs.on? ? Tabs.add_to(:issue_history, super, { issue: @issue }) : super
      end
    end
  end

  # The renderer of a journal detail property: responds to call(detail, view, no_html, options) and returns the line
  # as HTML, or as text when no_html (the text is also used in emails). One registered with a prop_key comes first.
  module JournalDetails
    @renderers = {}

    class << self
      def register(property, renderer, prop_key: nil)
        raise ArgumentError, "Invalid renderer for journal detail property '#{property}'" unless renderer.respond_to?(:call)

        @renderers[[property.to_s, prop_key&.to_s]] = renderer
      end

      def renderer_for(detail)
        property = detail.property.to_s
        @renderers[[property, detail.prop_key.to_s]] || @renderers[[property, nil]]
      end

      def clear = @renderers.clear
    end

    module IssuesHelperPatch
      def show_detail(detail, no_html = false, options = {})
        renderer = Tabs.on? && JournalDetails.renderer_for(detail)
        return renderer.call(detail, self, no_html, options) if renderer

        super
      end
    end
  end

  # The DSL of the proposal on Redmine::Plugin, for as long as core has none
  module PluginDsl
    def settings_tab(page, name, options = {}) = GkCoreStuff::Tabs.register(page, name, options)
    def project_settings_tab(name, options = {}) = settings_tab(:project_settings, name, options)
    def administration_settings_tab(name, options = {}) = settings_tab(:administration_settings, name, options)
    def user_settings_tab(name, options = {}) = settings_tab(:user, name, options)
    def group_settings_tab(name, options = {}) = settings_tab(:group, name, options)
    def issue_history_tab(name, options = {}) = settings_tab(:issue_history, name, options)

    def journal_detail(property:, renderer:, prop_key: nil)
      GkCoreStuff::JournalDetails.register(property, renderer, prop_key: prop_key)
    end
  end

  # On from the start: a register changes nothing until a plugin adds to it
  register :view_registries, issue: nil, defaults: { 'view_registries' => '1' }, in_core: -> { defined?(::Redmine::Tabs) } do
    ::Redmine::Plugin.include(PluginDsl) unless ::Redmine::Plugin.method_defined?(:settings_tab)
    ::ProjectsHelper.prepend(Tabs::ProjectsHelperPatch) unless ::ProjectsHelper < Tabs::ProjectsHelperPatch
    ::SettingsHelper.prepend(Tabs::SettingsHelperPatch) unless ::SettingsHelper < Tabs::SettingsHelperPatch
    ::UsersHelper.prepend(Tabs::UsersHelperPatch) unless ::UsersHelper < Tabs::UsersHelperPatch
    ::GroupsHelper.prepend(Tabs::GroupsHelperPatch) unless ::GroupsHelper < Tabs::GroupsHelperPatch
    ::IssuesHelper.prepend(Tabs::IssuesHelperPatch) unless ::IssuesHelper < Tabs::IssuesHelperPatch
    ::IssuesHelper.prepend(JournalDetails::IssuesHelperPatch) unless ::IssuesHelper < JournalDetails::IssuesHelperPatch
  end
end
