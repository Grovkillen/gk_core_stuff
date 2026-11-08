# frozen_string_literal: true

module GkCoreStuff
  # principal_marks: the principal's id on core's link to a user or a group, data-principal-id, so that a plugin knows
  # whose name a link is from the mark and never from the link's address (relative_url_root, a changed route) or its
  # text. Core draws every such link with ApplicationHelper#link_to_principal (link_to_user goes through it): a link
  # for a User it may link to and for a Group, plain text for anyone else. The id is handed to the one link_to the
  # helper draws, the way anchor_marks hands toggle_link's data on; where core draws no link nothing is marked, and
  # the link's address, class and text stay core's. Nothing shows. A prepend on core's helper, no copied views.
  # Always on; it stands aside the day core has the mark (compat's principal_marks).
  module PrincipalMarks
    ATTRIBUTE = 'data-principal-id'

    # The attributes of the link drawn for a principal: core's, with the id
    def self.link_options(html_options, id)
      (html_options || {}).merge(ATTRIBUTE => id.to_s)
    end

    # Prepended on ApplicationHelper
    module ApplicationHelperPatch
      def link_to_principal(principal, options = {})
        return super unless principal.respond_to?(:id) && principal.id && GkCoreStuff.on?(:principal_marks)

        @gk_core_stuff_principal_id = principal.id
        super
      ensure
        @gk_core_stuff_principal_id = nil
      end

      def link_to(name = nil, options = nil, html_options = nil, &block)
        id = @gk_core_stuff_principal_id
        return super if id.nil? || block || !(html_options.nil? || html_options.is_a?(Hash))

        @gk_core_stuff_principal_id = nil
        super(name, options, PrincipalMarks.link_options(html_options, id))
      end
    end
  end

  # Always on, without a setting: the mark is for other plugins and changes nothing that shows
  register :principal_marks, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:principal_marks) }, always: true do
    ::ApplicationHelper.prepend(PrincipalMarks::ApplicationHelperPatch) unless ::ApplicationHelper < PrincipalMarks::ApplicationHelperPatch
  end
end
