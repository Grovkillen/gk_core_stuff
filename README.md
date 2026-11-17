# GK Core Stuff

GK Core Stuff makes small fixes and additions to Redmine's own behaviour, one switchable module each. Where a module is a candidate for Redmine core, the plugin also carries the change as a patch per supported Redmine series, and the module only hooks in until core has it.

## Features

- **% done as text** (redmine.org #5284): shows the percentage as text with the progress bar in issue lists and for Progress bar custom fields in lists, so the value can be copied and read by screen readers. The text can be placed beside the bar, on the bar, below the bar or hidden (still read by screen readers and kept when copying), and 0% and 100% can each be shown or not. If core already has the setting, the module does not hook in and the settings page says so. Off by default.
- **The list of core's exports**: which of Redmine's pages send an export (issue lists, an issue, time entries, the time report, users, projects, members, permissions, the issue report, the gantt chart, wiki pages and the wiki, and a version), and what each is about. It hooks nothing into Redmine; gk_revisions names these exports by its file name rule and gk_records logs them, both from this one list. The file names and the log of exports, downloads and prints were earlier modules of this plugin.
- **One preference row per user**: Redmine can get two rows of a user's preferences and then read one and save the other. The module always reads the oldest row, checks the database before a new row is made, and merges extra rows into one. On by default.
- **AM/PM on the same line as the time**: a time in the 12-hour clock gets a no-break space before AM or PM, so a narrow column never leaves AM or PM alone on the next line. A 24-hour clock is not changed, and CSV exports keep the ordinary space. Off by default.
- **Register for tabs**: other plugins add their tabs to the settings pages of projects, the administration, users and groups and to an issue's history, without overriding Redmine's helpers. Several GK plugins require it, so it is always on and cannot be switched off; with nothing registered the pages are Redmine's own. If core already has the register, the module does not hook in.
- **Register for history lines**: other plugins say how their own lines in an issue's history are drawn, on the page, in the email and as text, without overriding Redmine's helper. Several GK plugins require it, so it is always on and cannot be switched off; with nothing registered the lines are Redmine's own. If core already has the register, the module does not hook in.
- **Marks on the issue page's sections**: the description, the files, the subtasks and the related issues each get a fixed mark on their container (`data-section`) and on their heading (the class `section-heading`), so that other plugins find a section without matching its heading's words. Nothing shows and nothing changes until a plugin reads the marks, so it is always on. If core already has the marks, the module does not hook in.
- **Links and text in formatted text**: one shared pass after Redmine has formatted a text (wiki pages, descriptions, notes, also in emails and exports), in which other plugins register a processor for the links (each with its address, its kind and whether it stands in code) or for the runs of text outside code, instead of each reading and rewriting the finished text. The text is read once for all of them, and is left exactly as Redmine wrote it when nothing is registered or nothing changes, so it is always on. GK GUI Stuff (links to other websites), GK Icons (icons in text) and GK Tags (`#tag` links) use it. The links in a custom field's value (the format Link, and a link pattern on another format) go through the same pass, given only to the link processors. If core already has the registry, the module does not hook in.
- **Marks in the issue reports**: every count in the issue reports (Summary and the detailed table) stands in a mark that says whether it is a status (with the status's id and whether it is closed), the open ones, the closed ones or the total (`data-report-column`, `data-status-id`, `data-status-closed`), so that other plugins know what a column is without going by its place, its heading's words or a status's name. Nothing shows, so it is always on. If core already has such marks, the module does not hook in.
- **Marks on the links to people and groups**: every link Redmine draws to a user or a group carries the user's or group's id (`data-principal-id`), so that other plugins know whose name it is without going by the link's address or text. Nothing shows, so it is always on. If core already has the mark, the module does not hook in.
- **Marks in the header's project path**: every project link in the project path at the top of the page (`a.root` and `a.ancestor`) carries the project's identifier (`data-project`), so that other plugins know where a link leads without counting links and separators. Nothing shows, so it is always on. If core already has the mark, the module does not hook in.
- **Asking whether a hook is called**: `GkCoreStuff.hook?(:hook_name, view: nil)` tells another plugin whether the page being drawn calls a view hook: Redmine's own hooks, and a hook GK Core Stuff adds when Redmine has it or when the views that call it come from GK Core Stuff's copies (not when another plugin's own copy of the view is used). With `view:` (for example `'settings/_general'`) it asks about one of the views that call the hook. A plugin draws its part on the hook when it is called and somewhere else only when it is not.
- **Looks**: small fixes of how Redmine's own pages look or read, each with a patch for every supported Redmine series: badges in the middle of a list's row and level with a page's heading, the row's check box in the middle of the row, a plugin's sidebar block with core's space above it, text rows in line with their label, the repositories table drawn as a list, equal margins in warning and "no data" boxes without an icon, the move handle in the icons' colour, `#` before issue numbers in lists, list headings aligned like their columns, equal widths for fields under each other and for the fields of a box on Redmine's settings pages, buttons and fields of one height on one line, "Save" instead of "Submit" on the button that saves a form, the loading box in the middle of the list it loads for, the browser's own texts (a field's message, a file field's button) in the page's language, check boxes Redmine shows in its own order in alphabetical order, a menu row's icon in the row's colour under the pointer, and the mark of an external link (and of an e-mail link) as a grey icon after the link that never ends up alone on a new line. Each is off, optional (on, and each person may switch it off) or forced; every look is off in a new installation, so Redmine's pages look as Redmine draws them until an administrator switches a look on. A look the running Redmine already has is not hooked in. Under the external links look, five values (all on until switched off) choose where outside formatted text a link to another site also gets the look: custom fields of the format Link, Link values to URL, the project's homepage on its overview, and the links GK People and GK Icons mark; GK GUI Stuff draws the mark in those places.
- **Dark mode** (a look): switched on, Redmine's pages follow the light or dark setting of the phone or computer and change along with it; its value is the choice of light, dark or automatic, each person's own under My account, Appearance when the look is optional, and the administrator's for everyone when it is forced. It covers Redmine's own pages with a stylesheet for every supported series; the header and the top menu keep Redmine's colours, code blocks keep their light ground and printed pages are always light. For other plugins: `GkCoreStuff::DarkMode.choice(user)` gives a person's choice, `GkCoreStuff::DarkMode.stylesheet_tags(view, page = nil)` gives the dark mode's stylesheets alone for a plugin that sets the class `dark-mode` on `html` itself, and `GkCoreStuff::DarkMode.drawn_by(name) { |user, page| ... }` lets a plugin that draws dark mode itself, such as a theme, take over the stylesheets while its block answers true.
- **Charts in the page's colours** (a look, off until switched on): while the page is dark or a theme draws it, Redmine's charts (the issue report's details and the repository's statistics) take GK GUI Stuff's category colours and the page's text, divider, frame and raised colours, and the revision graph and the Gantt chart's lines keep their hues at a lightness that holds 3:1 against the surface. In the light mode without a theme nothing changes. In Redmine 7.0 it needs GK Compat's ability `chart_js_module` to reach Chart.js.

## Requirements

- Redmine 6.0.0 or higher.
- Ruby 3.2 or later, the version your Redmine release runs on.
- PostgreSQL.

This plugin is developed and tested on Windows 11 with PostgreSQL only. That is a deliberate choice made for the maintainer's own convenience: the production system and the whole toolchain run there, and supporting other platforms and databases would cost time without adding anything for our own use. The Ruby code avoids needless Windows or PostgreSQL specific constructs, so it may well run on Linux, but that is untested and not supported. Its migrations use PostgreSQL's own types, so PostgreSQL is required.

GK plugins:

- Required: gk_gui_stuff (the forms on the settings page and the pictures on the page Administration > Appearance) and gk_compat (which Redmine series runs: the copies of Redmine's views and the dark mode's stylesheet for that series, whether the running Redmine already has what a module adds, so that the module stands aside, and "% done as text" also in custom fields with the progress bar format, where the Redmine series has them). Without GK GUI Stuff or GK Compat, with an older version of either than the one required, or with a GK GUI Stuff that is not active itself, what GK Core Stuff draws and offers is closed: no module hooks in except the shared pass over formatted text, no look is drawn, no hook or mark is added to Redmine's pages and other plugins cannot register tabs or history lines through it. What protects or leaves a trace holds all the same: PIN codes, tokens and identifiers are filtered from the log, the list of core's exports answers as usual, so that exports of Redmine's lists are still logged by the plugin that logs them, and the pass over formatted text runs, so that a processor another plugin registered still sets `rel` on links to other websites. GK Core Stuff has no permissions and no project modules of its own. The settings page says why in one line per plugin (it is missing, it is too old, with the version required, or it is installed but not active), and the migrations still run.
- Optional: gk_records (the modes of the looks and of the modules that change how Redmine's pages read, each person's own choices and their history; without it these are all off), gk_scenarios (the plugin's scenario steps and checks).

## Installation

The plugin directory must be named `gk_core_stuff` (it is the plugin id): `plugins/gk_core_stuff/`.

This version is installed anew and does not upgrade an earlier one: uninstall the earlier version first (as under Uninstall below, while its own files are in place), then install this one. Nothing is carried over from the earlier installation.

1. Unpack the release package into Redmine's `plugins` directory.
2. Run the migrations: `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`
3. Restart Redmine.

The plugin has no database tables of its own and no Gemfile. Its one migration is there for uninstalling.

Uninstall:

1. `bundle exec rake redmine:plugins:migrate NAME=gk_core_stuff VERSION=0 RAILS_ENV=production` (removes the plugin's settings and the choices kept in each person's preferences)
2. Remove the `plugins/gk_core_stuff` directory and restart Redmine.

## Configuration

Administration > Plugins > Configure (GK Core Stuff) has one box per module with a check box to switch it on or off (the registers for tabs and for history lines are always on and their boxes are locked). The looks, "% done as text" with its position and 0%/100% options, AM/PM on the same line as the time and Redmine's version in the footer are appearance settings under Administration > Appearance (GK GUI Stuff), where each look gets its mode: Off, Optional or Forced.

## Usage

- With "% done as text" on, the percentage appears next to the progress bars in issue lists.
- Each person switches off the optional looks they do not want under My account, Appearance (GK GUI Stuff), where they also choose light, dark or automatic when Dark mode is optional.

## Changelog

See CHANGELOG.md.

## License

GPL-2.0-or-later, the same license as Redmine. Copyright (C) 2026 Jimmy Westberg. See the LICENSE file for the full text.

The icons after external links and e-mail links are from Tabler Icons (MIT License, Copyright (c) 2020-2025 Paweł Kuna), the same icons Redmine uses, unchanged. Their license text is in LICENSE_TABLER_ICONS.txt.
