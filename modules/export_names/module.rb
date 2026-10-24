# frozen_string_literal: true

module GkCoreStuff
  # export_names: what core writes out (issue lists, an issue, time, users, projects, members, permissions, reports,
  # gantt, wiki pages and the wiki, a version) gets its file name from revisions' one rule (GkRevisions::Names). One
  # hook: send_data and send_file_headers! in ApplicationController, and a table, as data, of which controller, action
  # and format is which kind of export. What is not in the table is never touched, so an attachment or a file from a
  # repository keeps its own name. Switched off, or without revisions, core names its files as it always has.
  module ExportNames
    # "controller#action" => [kind, values: ->(controller) { { token => value } }]
    TABLE = {
      'issues#index' => ['core.issues', ->(c) { { 'resource' => c.instance_variable_get(:@query)&.name } }],
      'issues#show' => ['core.issue', ->(c) { i = c.instance_variable_get(:@issue); { 'id' => i&.id, 'title' => i&.subject } }],
      'timelog#index' => ['core.timelog', ->(c) { { 'resource' => c.instance_variable_get(:@query)&.name } }],
      'timelog#report' => ['core.time_report', ->(_c) { {} }],
      'users#index' => ['core.users', ->(c) { { 'resource' => c.instance_variable_get(:@query)&.name } }],
      'projects#index' => ['core.projects', ->(c) { { 'resource' => c.instance_variable_get(:@query)&.name } }],
      'members#index' => ['core.members', ->(_c) { {} }],
      'roles#permissions' => ['core.permissions', ->(_c) { {} }],
      'reports#issue_report_details' => ['core.issue_report', ->(c) { { 'resource' => c.params[:detail] } }],
      'gantts#show' => ['core.gantt', ->(_c) { {} }],
      'wiki#show' => ['core.wiki_page', ->(c) { { 'title' => c.instance_variable_get(:@page)&.title } }],
      'wiki#export' => ['core.wiki', ->(_c) { {} }],
      'versions#show' => ['core.version', ->(c) { { 'title' => c.instance_variable_get(:@version)&.name } }]
    }.freeze
    KIND_TOKENS = {
      'core.issues' => %w[resource], 'core.issue' => %w[id title], 'core.timelog' => %w[resource], 'core.users' => %w[resource],
      'core.projects' => %w[resource], 'core.issue_report' => %w[resource], 'core.wiki_page' => %w[title], 'core.version' => %w[title]
    }.freeze

    class << self
      def engine? = defined?(::GkRevisions::Names)
      def on? = GkCoreStuff.on?(:export_names) && engine?

      # The kinds, declared in revisions after start (revisions loads after core_stuff); their default extension is the
      # one core gives most often, and the name keeps the extension of the file core makes
      def declare!
        return unless engine?

        TABLE.values.map(&:first).uniq.each do |kind|
          ::GkRevisions::Names.register(kind, plugin: :gk_core_stuff, label_key: "label_gk_core_stuff_export_#{kind.split('.').last}",
                                               ext: 'csv', tokens: KIND_TOKENS.fetch(kind, []))
        end
      end

      # The options with the file name from the rule, when the controller and action are core's export
      def rename(controller, options)
        return options unless options.is_a?(Hash) && options[:filename].present? && on?

        kind, values = TABLE["#{controller.controller_path}##{controller.action_name}"]
        return options unless kind

        ext = File.extname(options[:filename].to_s).delete_prefix('.').presence
        project = controller.instance_variable_get(:@project)
        name = ::GkRevisions::Names.file_name(kind, values.call(controller).compact, project: project, ext: ext)
        options.merge(filename: name)
      rescue StandardError => e
        Rails.logger.warn("[gk_core_stuff] export name kept as core gave it (#{e.class}: #{e.message})")
        options
      end
    end

    # ApplicationController: the two ways core sends a file it made
    module ControllerPatch
      private

      def send_data(data, options = {})
        super(data, ExportNames.rename(self, options))
      end

      def send_file_headers!(options)
        super(ExportNames.rename(self, options))
      end
    end
  end

  register :export_names, issue: nil, defaults: { 'export_names' => '1' }, in_core: -> { false } do
    ::ApplicationController.prepend(ExportNames::ControllerPatch) unless ::ApplicationController < ExportNames::ControllerPatch
  end
end
