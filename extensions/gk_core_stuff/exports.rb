# frozen_string_literal: true

module GkCoreStuff
  # exports: which of core's actions send a file core made (issue lists, an issue, time, users, projects, members,
  # permissions, reports, gantt, wiki pages and the wiki, a version), as data: the controller and action, the kind of
  # export, and what it is about as core has it when it sends the file. The plugins that name or log exports read it
  # here, so the list is one: revisions names them by its rule, records logs them as events. What is not in the list is
  # not core's export, so an attachment or a file from a repository is never one. Nothing is hooked into core.
  module Exports
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
    # The values each kind gives beyond the common ones
    KIND_TOKENS = {
      'core.issues' => %w[resource], 'core.issue' => %w[id title], 'core.timelog' => %w[resource], 'core.users' => %w[resource],
      'core.projects' => %w[resource], 'core.issue_report' => %w[resource], 'core.wiki_page' => %w[title], 'core.version' => %w[title]
    }.freeze

    module_function

    def kinds = TABLE.values.map(&:first).uniq
    def tokens(kind) = KIND_TOKENS.fetch(kind.to_s, [])

    # The kind's name in the locales (Ärendelista, Ärende and the rest)
    def label_key(kind) = "label_gk_core_stuff_export_#{kind.to_s.split('.').last}"

    def route(controller) = "#{controller.controller_path}##{controller.action_name}"

    # The kind of export the controller's action sends, or nil
    def kind_of(controller) = TABLE[route(controller)]&.first

    # What the export is about: { token => value }, without the values core has not got
    def values_of(controller)
      entry = TABLE[route(controller)]
      entry ? entry.last.call(controller).compact : {}
    end
  end
end
