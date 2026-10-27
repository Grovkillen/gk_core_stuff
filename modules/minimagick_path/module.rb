# frozen_string_literal: true

module GkCoreStuff
  # minimagick_path: the Gantt chart as PNG with the ImageMagick that configuration.yml names. Core gives MiniMagick
  # the folder of imagemagick_convert_command (cli_path), but MiniMagick 5 has no cli_path, so core warns and MiniMagick
  # runs "convert" from the PATH. On Windows that is the system's own convert.exe (a file system tool), and the PNG
  # fails with an internal error. When the command is ImageMagick 7's magick, it is given to MiniMagick as its prefix,
  # so that MiniMagick runs "magick convert ...", which ImageMagick 7 takes. On from the start; core's thumbnails use
  # the command themselves and are not touched.
  module MinimagickPath
    class << self
      def command = ::Redmine::Configuration['imagemagick_convert_command'].to_s

      # magick or magick.exe, the only command that takes "convert" as its first argument
      def magick? = File.basename(command, '.*').casecmp?('magick')

      def apply!
        return unless GkCoreStuff.on?(:minimagick_path) && magick? && defined?(::MiniMagick)
        # with magick on the PATH MiniMagick finds ImageMagick 7 itself, and a prefix would give "magick magick"
        return if ::MiniMagick.imagemagick7?

        ::MiniMagick.cli_prefix = command
      rescue StandardError => e
        Rails.logger.warn("[gk_core_stuff] minimagick_path: #{e.class}: #{e.message}")
      end
    end
  end

  # in_core: core's own cli_path still works (compat: a MiniMagick that has it)
  register :minimagick_path, issue: nil, defaults: { 'minimagick_path' => '1' },
                             in_core: -> { GkCoreStuff.core_has?(:minimagick_cli_path) } do
    Rails.configuration.after_initialize { MinimagickPath.apply! }
  end
end
