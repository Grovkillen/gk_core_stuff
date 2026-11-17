# frozen_string_literal: true

module GkCoreStuff
  # external_links: the mark of an external link in formatted text is Tabler's external-link icon after the link text,
  # never on a line of its own, mirrored in a right to left language, not printed: the form of Feature #44691
  # (docs/modules/external_links.md). The link and its icon take the colour role for external links
  # (--gk-role-link-external) and the link a dotted underline. GK GUI Stuff gives the tooltip with the domain and marks
  # a link to the instance's own address (class gk-link-own), which is drawn as an internal link. A link to an e-mail
  # address gets core's e-mail icon in the role muted, GK's own addition. The classes external and email
  # stay on the links. Stands aside in a series that has the change (compat's ability external_link_icon). Also on for
  # someone not logged in, who reads the same texts.
  #
  # The row's values say where, outside formatted text, a link to another host also gets the look: a flag per place,
  # on until the administrator switches it off. This plugin owns the row and so declares them; GK GUI Stuff marks the
  # links (it reads the flags and adds nothing to the row).
  # * field_link: a custom field of the format link; url_pattern: the address pattern of the other formats;
  # * project_homepage: the project's homepage on the project's overview;
  # * people and icons: links those plugins mark themselves.
  module ExternalLinks
    PLACES = %w[field_link url_pattern project_homepage people icons].freeze

    def self.value_name(place) = "place_#{place}"

    def self.place_values
      PLACES.to_h do |p|
        [value_name(p), { kind: :flag, default: true, label: :"label_gk_core_stuff_ext_place_#{p}",
                          info: :"text_gk_core_stuff_ext_place_#{p}_info" }]
      end
    end
  end

  Looks.register :external_links, stylesheet: true, anonymous: true, values: ExternalLinks.place_values,
                                  in_core: -> { GkCoreStuff.core_has?(:external_link_icon) }
end
