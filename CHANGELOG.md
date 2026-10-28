# Changelog

All notable changes to GK Core Stuff are documented in this file.

## 1.03.000 (2026-10-28)

### Added

* Look Menu icons in the row's colour: in a menu (a button row's and a note's ..., the issue list's right click) the icon of the row under the pointer keeps the row's colour, as its text does, instead of turning red as the icon of an ordinary link does (Redmine 6.1 and later; 6.0 already does so).

## 1.02.000 (2026-10-28)

### Added

* Hooks in Redmine's views for other plugins, in four modules that are always on and stand aside when Redmine has the hooks itself: the page's frame (the top and bottom of the header and the footer, the top of the content and the sidebar, after the page title, around the issue on the issue page), the button row and the menus (a hook in the button row of sixteen pages and the actions menu of eight, and menus that plugins add items to for an issue, the issue list's context menu, a project, a user and a version), the forms (the top and bottom of seven forms and after sections of the issue and user forms) and the lists (a row's classes and content after the row in the issue, project and user lists). The views are Redmine's own with the hooks added, one copy per supported Redmine series; where another plugin already overrides one of them, that plugin's view is used. The settings page lists the four with their views and the hooks in use.

## 1.01.000 (2026-10-27)

### Added

* A plugin can register how its lines in an issue's history are drawn for every key that matches a pattern, not only for one key.

### Changed

* This version is installed anew and does not upgrade an earlier one: uninstall the earlier version first (migrate it down to 0 while its own files are in place), then install this one. Nothing is carried over from the earlier installation.
* The registers for tabs and for history lines are two modules instead of one, so that each stands aside by itself the day Redmine has it. Both are always on and can no longer be switched off, since other GK plugins require them for their tabs and history lines. The settings page shows each as a locked box with what is registered in it; the history lines registered are now listed too.
* The export log and the file names of Redmine's exports have moved to the plugins they always needed: the log of exports, downloads and prints is part of GK Records 1.04.000, and the names from the rule for file names are part of GK Revisions 1.00.000. GK Core Stuff keeps the list of which of Redmine's actions send an export, which both read; without those plugins the two did nothing here either.
* Whether Redmine itself already has what a module adds is asked of GK Compat 1.01.000 or later instead of looked for in Redmine's classes and settings. Without GK Compat, or with an older one, every module hooks in as before.
* Uninstalling (migrating the plugin down to 0) takes the plugin's keys out of the users' preferences in the migration itself, without calling the plugin's own code.

## 1.00.000 (2026-10-24)

* First release.
