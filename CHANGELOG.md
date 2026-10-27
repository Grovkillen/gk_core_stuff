# Changelog

All notable changes to GK Core Stuff are documented in this file.

## 1.01.000 (2026-10-27)

### Added

* A plugin can register how its lines in an issue's history are drawn for every key that matches a pattern, not only for one key.

### Changed

* This version is installed anew and does not upgrade an earlier one: uninstall the earlier version first (migrate it down to 0 while its own files are in place), then install this one. Nothing is carried over from the earlier installation.
* The registers for tabs and for history lines are two modules instead of one, so that each stands aside by itself the day Redmine has it. Both are always on and can no longer be switched off, since other GK plugins require them for their tabs and history lines. The settings page shows each as a locked box with what is registered in it; the history lines registered are now listed too.
* The export log and the file names of Redmine's exports have moved to the plugins they always needed: the log of exports, downloads and prints is part of GK Records 1.04.000, and the names from the rule for file names are part of GK Revisions 1.00.000. GK Core Stuff keeps the list of which of Redmine's actions send an export, which both read; without those plugins the two did nothing here either.
* Whether Redmine itself already has what a module adds is asked of GK Compat 1.01.000 or later instead of looked for in Redmine's classes and settings. Without GK Compat, or with an older one, every module hooks in as before.
* Uninstalling (migrating the plugin down to 0) takes the plugin's keys out of the users' preferences in the migration itself, without calling the plugin's own code.
* Released as one package with GK Records 1.04.000, GK GUI Stuff 1.01.000, GK Revisions 1.00.000, GK Compat 1.01.000, and GK Icons and the other GK plugins that declare functions, in the versions released at the same time: install them together.

## 1.00.000 (2026-10-24)

* First release.
