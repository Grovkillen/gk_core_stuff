# frozen_string_literal: true

# Merged at 1.00.000. core_stuff has no tables of its own; this first migration is where uninstalling it takes away
# what it kept in core's tables: its row in settings and the gk_core_stuff_ keys in each person's
# preferences. Its down runs last at redmine:plugins:migrate NAME=gk_core_stuff VERSION=0.
class GkCoreStuffUninstall < ActiveRecord::Migration[6.1]
  def up
    # nothing to make: the settings row is core's own, made when the settings are first saved
  end

  def down
    Setting.where(name: 'plugin_gk_core_stuff').delete_all
    strip_preferences('gk_core_stuff_')
  end

  private

  # Uninstalling (down to 0, this migration last) takes the plugin's own keys out of the users' preferences in core's
  # user_preferences; the rows and core's own keys stay. In Ruby, so that it is the same on every database.
  def strip_preferences(prefix)
    ::UserPreference.reset_column_information
    ::UserPreference.find_each do |pref|
      others = pref.read_attribute(:others)
      next unless others.respond_to?(:keys) && others.keys.any? { |k| k.to_s.start_with?(prefix) }

      pref.update_column(:others, others.reject { |k, _| k.to_s.start_with?(prefix) })
    end
  end
end
