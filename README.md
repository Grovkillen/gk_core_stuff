# GK Core Stuff

GK Core Stuff makes small fixes and additions to Redmine's own behaviour, one switchable module each. Where a module is a candidate for Redmine core, the plugin also carries the change as a patch per supported Redmine series, and the module only hooks in until core has it.

## Features

- **% done as text** (redmine.org #5284): shows the percentage as text with the progress bar in issue lists and for Progress bar custom fields in lists, so the value can be copied and read by screen readers. The text can be placed beside the bar, on the bar, below the bar or hidden (still read by screen readers and kept when copying), and 0% and 100% can each be shown or not. If core already has the setting, the module does not hook in and the settings page says so. Off by default.
- **File names for core's exports**: issue lists, an issue, time entries, the time report, users, projects, members, permissions, the issue report, the gantt chart, wiki pages and the wiki, and a version get their file names from the file name rule in gk_revisions. Attachments and files from repositories always keep their names. Without gk_revisions core names files as before. On by default.
- **Log of exports, downloads and prints**: every export (core's and the GK plugins'), every attachment downloaded and every print asked for in the browser is written as an event in gk_records on what it is about, with who, when, file name, SHA-256 checksum, size, query and number of rows, and IP address. A print means the browser started printing; it does not say whether paper came out. Events are seen by users with the project permission "View exports and prints" (administrators see all). Without gk_records nothing is logged. On by default.
- **Exports with manifest**: with the export log on, a named export can be downloaded as a zip with the file and a `manifest.json` (source, route, format, times, account, rows, size and SHA-256), offered as a check box in core's CSV dialog and a "with manifest" link beside the other formats.
- **One preference row per user**: Redmine can get two rows of a user's preferences and then read one and save the other. The module always reads the oldest row, checks the database before a new row is made, and merges extra rows into one. On by default.
- **AM/PM on the same line as the time**: a time in the 12-hour clock gets a no-break space before AM or PM, so a narrow column never leaves AM or PM alone on the next line. A 24-hour clock is not changed, and CSV exports keep the ordinary space. On by default.
- **Looks**: small fixes of how Redmine's own pages look or read, each with a patch for every supported Redmine series: badges in the middle of a list's row and level with a page's heading, the row's check box in the middle of the row, a plugin's sidebar block with core's space above it, text rows in line with their label, the repositories table drawn as a list, equal margins in warning and "no data" boxes without an icon, the move handle in the icons' colour, `#` before issue numbers in lists, list headings aligned like their columns, equal widths for fields under each other and for the fields of a box on Redmine's settings pages, buttons and fields of one height on one line, "Save" instead of "Submit" on the button that saves a form, the loading box in the middle of the list it loads for, the browser's own texts (a field's message, a file field's button) in the page's language, and check boxes Redmine shows in its own order in alphabetical order. Each is off, optional (on, and each person may switch it off) or forced; most are optional from the start, and `#` before issue numbers, "Save" instead of "Submit" and the loading box are off. A look the running Redmine already has is not hooked in.

## Requirements

- Redmine 6.0.0 or higher.
- Ruby 3.2 or later, the version your Redmine release runs on.
- PostgreSQL.

This plugin is developed and tested on Windows 11 with PostgreSQL only. That is a deliberate choice made for the maintainer's own convenience: the production system and the whole toolchain run there, and supporting other platforms and databases would cost time without adding anything for our own use. The Ruby code avoids needless Windows or PostgreSQL specific constructs, so it may well run on Linux, but that is untested and not supported. Its migrations use PostgreSQL's own types, so PostgreSQL is required.

GK plugins:

- Required: none.
- Optional: gk_revisions (file names for core's exports from its file name rule), gk_records (the log of exports, downloads and prints), gk_compat ("% done as text" also in custom fields with the progress bar format, where the Redmine series has them), gk_scenarios (the plugin's scenario steps and checks).

## Installation

The plugin directory must be named `gk_core_stuff` (it is the plugin id): `plugins/gk_core_stuff/`.

1. Unpack the release package into Redmine's `plugins` directory.
2. Run the migrations: `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`
3. Restart Redmine.

The plugin has no database tables of its own and no Gemfile. Its one migration is there for uninstalling.

Uninstall:

1. `bundle exec rake redmine:plugins:migrate NAME=gk_core_stuff VERSION=0 RAILS_ENV=production` (removes the plugin's settings and the choices kept in each person's preferences)
2. Remove the `plugins/gk_core_stuff` directory and restart Redmine.

## Configuration

Administration > Plugins > Configure (GK Core Stuff) has one box per module with a check box to switch it on or off, plus the position and 0%/100% options for "% done as text". The file name patterns for core's exports are set on gk_revisions' File names page in Administration. The box Looks gives each look its mode: Off, Optional or Forced.

Grant the project permission "View exports and prints" under Administration > Roles and permissions to the roles that should see the export log events.

## Usage

- With "% done as text" on, the percentage appears next to the progress bars in issue lists.
- Exports from issue lists, issues, time entries, wiki pages and the other core pages listed above download under names from the file name rule.
- Export, download and print events appear among the gk_records events on the issue, wiki page, project or user they concern, for users with the permission.
- The "with manifest" option appears in core's CSV export dialog and beside the other export formats.
- Each person switches off the optional looks they do not want under My account, Preferences.

## Changelog

See CHANGELOG.md.

## License

GPL-2.0-or-later, the same license as Redmine. Copyright (C) 2026 Jimmy Westberg. See the LICENSE file for the full text.
