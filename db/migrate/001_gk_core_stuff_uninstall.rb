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
    GkCoreStuff::Looks.forget_all!
  end
end
