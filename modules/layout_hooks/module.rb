# frozen_string_literal: true

module GkCoreStuff
  # layout_hooks (step 01 of the proposal view_hooks, redmine/core_proposals/view_hooks/stege/01_layout.patch): hooks
  # at the top and bottom of the header, at the top of the content, at the top of the sidebar, after the page title,
  # at the top and bottom of the footer, and on the issue page before, at the end of and after div.issue. Core calls
  # none of them. The views are core's own with the step's lines added, one copy per series in views/<series>/, made
  # by pipeline/scripts/development/core_views.ps1 from redmine/zip/ and the step's patch (never by hand; SOURCE.yml
  # says from which zip and patch), and chosen for the running series by compat (GkCoreStuff.series_views). The helper
  # methods (the title hook, the sidebar's top) are hooked in with prepend. The hooks change nothing until a plugin
  # listens to them, so the module is always on; it stands aside the day core has the step (compat's layout_hooks).
  module LayoutHooks
    # The hooks the step adds (listed on the settings page with the ones some plugin listens to)
    HOOKS = %i[view_layouts_base_header_top view_layouts_base_header_bottom view_layouts_base_sidebar_top
               view_layouts_base_content_top view_layouts_base_title_after view_layouts_base_footer_top
               view_layouts_base_footer_bottom view_issues_show_top view_issues_show_details_end
               view_issues_show_bottom].freeze

    def self.views_dir = GkCoreStuff.series_views(:layout_hooks)

    # Whether core renders the module's own layouts/base and users/edit (not a plugin's copy, not core's): only then do
    # the title hook and the sidebar's top belong on the page. Core's layout never prints the sidebar's top, and core's
    # users/edit puts the avatar at the title's last space, which would land inside the hook's output. Asked when a
    # page is drawn, after every plugin has registered its views, and kept.
    def self.own_views?
      return @own_views unless @own_views.nil?

      dir = GkCoreStuff.series_dirs['layout_hooks']
      @own_views =
        if dir.nil? then false
        else
          ctx = ::ActionController::Base.new.lookup_context
          %w[layouts/base users/edit].all? { |v| File.expand_path(ctx.find_template(v).identifier.to_s).start_with?(File.expand_path(dir)) }
        end
    rescue StandardError
      @own_views = false
    end

    module ApplicationHelperPatch
      def title(*args)
        html = super
        GkCoreStuff.on?(:layout_hooks) && LayoutHooks.own_views? ? html + call_hook(:view_layouts_base_title_after, title: args) : html
      end

      def sidebar_content?
        super || (GkCoreStuff.on?(:layout_hooks) && LayoutHooks.own_views? && view_layouts_base_sidebar_top_hook_response.present?)
      end

      def view_layouts_base_sidebar_top_hook_response
        @view_layouts_base_sidebar_top_hook_response ||= call_hook(:view_layouts_base_sidebar_top)
      end
    end
  end

  # Always on, without a setting: the hooks are for other plugins and change nothing until one listens
  register :layout_hooks, issue: 44660, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:layout_hooks) }, always: true do
    # the helper methods only together with the views: without them core's own layout is drawn
    if GkCoreStuff.prepend_series_views(:layout_hooks)
      ::ApplicationHelper.prepend(LayoutHooks::ApplicationHelperPatch) unless ::ApplicationHelper < LayoutHooks::ApplicationHelperPatch
    end
  end
end
