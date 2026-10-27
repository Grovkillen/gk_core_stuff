# frozen_string_literal: true

module GkCoreStuff
  # avatar_sources. Core's AvatarsHelper#avatar knows only Gravatar (and in 7.0 the initials); a plugin that shows a
  # picture from elsewhere (an uploaded picture, an icon, a folder of photos) has to overwrite the helper. The upstream
  # form is patch/avatar_sources-<series>.diff: a register, Redmine::AvatarSources, where a source is added with a
  # position, and avatar asks the sources in order before Gravatar; the first that has a picture for the user wins.
  # Here the same register is GkCoreStuff::AvatarSources, hooked in with prepend. A source is a block
  # (user, options, view) that returns the HTML of the picture, or nil to let the next one answer; options are core's
  # (size, class, title). Only users and groups ask the sources: never the anonymous user, and never the string with an
  # e-mail address that core's avatar also takes. With no source registered, or the module off,
  # avatar is core's own.
  module AvatarSources
    Source = Struct.new(:key, :position, :block)

    @sources ||= {}

    class << self
      # A plugin adds its source: a lower position is asked first. Registering the same key again replaces it.
      def register(key, position:, &block)
        @sources[key.to_s] = Source.new(key.to_s, position.to_i, block)
      end

      def unregister(key) = @sources.delete(key.to_s)
      def sources = @sources.values.sort_by { |s| [s.position, s.key] }
      def on? = GkCoreStuff.on?(:avatar_sources)

      # The first source's picture for the user, or nil; a source that fails is passed over (logged), never shown
      def render(user, options, view)
        return nil unless on? && user.is_a?(::Principal) && !user.is_a?(::AnonymousUser)

        sources.each do |s|
          html = s.block.call(user, options, view)
          return html if html.present?
        rescue StandardError => e
          ::Rails.logger.warn("[gk_core_stuff] avatar source #{s.key}: #{e.class}: #{e.message}")
        end
        nil
      end
    end

    # AvatarsHelper#avatar: the sources first, then core's own (Gravatar, and the initials in 7.0)
    module HelperPatch
      def avatar(user, options = {})
        html = GkCoreStuff::AvatarSources.render(user, options.dup, self)
        return html if html

        super
      end
    end
  end

  # On from the start: a register changes nothing until a plugin adds a source
  register :avatar_sources, issue: nil, defaults: { 'avatar_sources' => '1' }, in_core: -> { GkCoreStuff.core_has?(:avatar_sources) } do
    ::AvatarsHelper.prepend(AvatarSources::HelperPatch) unless ::AvatarsHelper < AvatarSources::HelperPatch
  end
end
