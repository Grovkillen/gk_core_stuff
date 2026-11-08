# frozen_string_literal: true

module GkCoreStuff
  # formatting_processors (the proposal redmine/core_proposals/formatting_processors): one pass over the links and the
  # runs of text of every formatted text, which plugins hook into, so that no plugin parses and rewrites the HTML that
  # textilizable returns on its own. Core formats a text in steps (the formatter, then Redmine links, wiki links,
  # macros, sections, headings and the table of contents); the pass runs once after the last step, on every call, so it
  # sees the whole text the reader gets: links the formatter built, Redmine and wiki links, and macro output (also
  # output that 7.0 keeps aside while it parses the sections, which is back in place by then). It never runs inside
  # the formatter, whose output core may cache per object and give to every reader, while what a plugin adds can
  # depend on the reader (a setting, a new tab, a project's module).
  #
  # A plugin registers under its id, with a link processor, a text processor or both:
  #   GkCoreStuff::FormattingProcessors.register(:gk_a, link: GkA::Links, text: GkA::Text)
  # * A link processor responds to call(link, context) and gets every link (an a element with an address) as a Link:
  #   its address (url), what core counts it as (kind: :external for an address with a scheme other than mailto or
  #   one starting with //, :email for mailto, :anchor for #..., :internal for any other), whether it stands in code
  #   (in_code?), and its attributes, which the processor may read and set (add_class, add_rel, [] and []=), and
  #   append, which adds HTML at the end of the link's content.
  # * A text processor responds to call(run, context) and gets every run of text outside pre, code, textarea, script
  #   and style as a TextRun: the text as the reader reads it (run.text, entities decoded) and whether it stands inside
  #   a link (run.in_link?). It returns nil to leave the run, or HTML (escaped by the processor) that takes the run's
  #   place. The text processors come in the order they were registered: the plain text a processor's HTML leaves at
  #   the run's place is given to the processors after it, its elements are not.
  # * Either may respond to active?(context): false leaves it out for this text (a setting, a reader, a project's
  #   module), and when no processor is active the text is not parsed at all.
  # The Context has the view, the object and attribute, the project (as core's textilizable finds it), only_path
  # (false in mail and exports), the options, the text as written before formatting (source) and the view's request
  # (nil in mail), and memo(key) { ... } for what a processor reads once per text. origin says what was formatted:
  # :text for textilizable, :custom_value for the formatted value of a custom field (below).
  # The same pass also runs over the formatted value of a custom field (core's field formats build the links of a
  # Link field and of a link pattern with link_to and then sanitize them, which drops a class or a data attribute a
  # plugin would set on the link): after Redmine::FieldFormat::Base#formatted_custom_value, the one way core formats a
  # custom value (format_object of a CustomValue or CustomFieldValue), with the HTML only (html_safe), a Context whose
  # origin is :custom_value, object the custom value, attribute :value and source the value as stored. Only the link
  # processors are given it; a text processor is for formatted text. This part is the proposal's open question
  # ("the same pass for other HTML with links"), kept here until core answers it: it is a module of its own
  # (formatting_processors_values, compat's ability of the same name), which goes on running when core has the
  # registry for formatted text, with the link processors kept here as well.
  # The links come first, then the runs; links a text processor adds are not given to the link processors. A text
  # formatted inside another (core's collapse and include macros) passes once on its own and again in the outer text,
  # so a processor leaves what it marked before as it is. What nothing changed comes back as it came; otherwise the
  # text is written out again from the one parse. A processor that fails is left out for that text and logged.
  # Always on; it stands aside the day core has the registry (compat's formatting_processors), and register then hands
  # the processors to core's own (Redmine::WikiFormatting::Processors) and keeps them here too, for the custom values.
  module FormattingProcessors
    # Where a link counts as code, and where no run of text is given to the processors
    CODE = %w[pre code].freeze
    NO_TEXT = %w[pre code textarea script style].freeze
    SCHEME = /\A([a-z][a-z0-9+.-]*):/i

    # The view's request, nil in mail or without a view
    def self.request_of(view)
      view.respond_to?(:request) ? view.request : nil
    rescue StandardError
      nil
    end

    # What a text is formatted for, built before core formats it (core changes the options it is given)
    class Context
      ORIGINS = %i[text custom_value].freeze

      attr_reader :view, :object, :attribute, :project, :only_path, :options, :origin

      def initialize(view: nil, object: nil, attribute: nil, project: nil, only_path: true, options: {}, source: nil, origin: :text, &source_block)
        raise ArgumentError, "Invalid origin '#{origin}'" unless ORIGINS.include?(origin)

        @origin = origin
        @view = view
        @object = object
        @attribute = attribute
        @project = project
        @only_path = only_path ? true : false
        @options = options || {}
        @source = source
        @source_block = source_block
        @memo = {}
      end

      # The text as written, before formatting
      def source
        @source = (@source_block ? @source_block.call : '').to_s if @source.nil?
        @source
      end

      def request
        @memo.key?(:__request) ? @memo[:__request] : (@memo[:__request] = FormattingProcessors.request_of(view))
      end

      def memo(key)
        @memo.key?(key) ? @memo[key] : (@memo[key] = yield)
      end

      def custom_value? = @origin == :custom_value
    end

    # A link of the text, for the link processors
    class Link
      attr_reader :url, :kind

      def initialize(node, kind, in_code)
        @node = node
        @url = node['href'].to_s
        @kind = kind
        @in_code = in_code
        @changed = false
      end

      def in_code? = @in_code
      def changed? = @changed
      def [](name) = @node[name.to_s]

      # nil removes the attribute
      def []=(name, value)
        name = name.to_s
        if value.nil?
          return unless @node.key?(name)

          @node.remove_attribute(name)
        else
          return if @node[name] == value.to_s

          @node[name] = value.to_s
        end
        @changed = true
      end

      def classes = @node['class'].to_s.split

      # false when the class was there already
      def add_class(name)
        list = classes
        return false if list.include?(name.to_s)

        self['class'] = (list << name.to_s).join(' ')
        true
      end

      # The values added to rel, what is there kept first; false when nothing was missing
      def add_rel(*values)
        list = @node['rel'].to_s.split
        merged = (list + values.flatten.map(&:to_s)).uniq
        return false if merged == list

        self['rel'] = merged.join(' ')
        true
      end

      # HTML added at the end of the link's content (escaped by the caller)
      def append(html)
        @node.add_child(html.to_s)
        @changed = true
      end

      # Whether an element inside the link has the class: for a processor's own earlier mark (an inner text passes
      # again in the outer text)
      def contains_class?(name)
        @node.css('*').any? { |n| n['class'].to_s.split.include?(name.to_s) }
      end
    end

    # A run of text, for the text processors
    TextRun = Struct.new(:text, :in_link) do
      def in_link? = in_link ? true : false
    end

    @link = {}
    @text = {}

    class << self
      # A plugin's processors under its id; again under the same id replaces them (a reload registers again). Once
      # core has the registry, they go to core's as well; the ones kept here then serve only the custom values' pass
      # (formatting_processors_values), as the pass over formatted text stands aside.
      def register(name, link: nil, text: nil)
        [link, text].compact.each do |p|
          raise ArgumentError, "Invalid formatting processor for '#{name}'" unless p.respond_to?(:call)
        end
        ::Redmine::WikiFormatting::Processors.register(name, link: link, text: text) if in_core?

        key = name.to_s
        link ? @link[key] = link : @link.delete(key)
        text ? @text[key] = text : @text.delete(key)
      end

      def unregister(name)
        @link.delete(name.to_s)
        @text.delete(name.to_s)
      end

      def link_processors = @link.values
      def text_processors = @text.values

      # For the settings page: the id and what it registered
      def registered
        (@link.keys | @text.keys).map { |k| "#{k} (#{[(@link[k] && 'link'), (@text[k] && 'text')].compact.join(', ')})" }
      end

      def clear
        @link.clear
        @text.clear
      end

      def in_core? = GkCoreStuff.in_core?(:formatting_processors)
      def on? = GkCoreStuff.on?(:formatting_processors)

      # The custom values' pass: on of its own, also when core has the registry for formatted text
      def values_on? = GkCoreStuff.on?(:formatting_processors_values)

      # What core counts a link as, by its address alone; a backslash at the start counts as a slash, as a browser
      # reads it (/\host and \\host lead to another host as //host does)
      def kind_of(url)
        s = url.to_s.delete("\t\n\r").strip
        return :anchor if s.start_with?('#')
        return :external if s.match?(%r{\A[/\\]{2}})
        return :internal if s.start_with?('/')

        scheme = s[SCHEME, 1]
        return :internal unless scheme

        scheme.casecmp?('mailto') ? :email : :external
      end

      # The context of a call to textilizable(text, options) or textilizable(object, attribute, options), found as
      # core finds it; nil for arguments core refuses (core raises then)
      def context_for(view, args)
        options = args.last.is_a?(Hash) ? args.last : {}
        plain = options.equal?(args.last) ? args[0...-1] : args
        case plain.size
        when 1
          obj = options[:object]
          attr = nil
          text = plain.first
          source = -> { text }
        when 2
          obj, attr = plain
          source = -> { obj.send(attr) }
        else
          return nil
        end
        project = options[:project] || view.instance_variable_get(:@project) || (obj.respond_to?(:project) ? obj.project : nil)
        Context.new(view: view, object: obj, attribute: attr, project: project, only_path: options[:only_path] != false,
                    options: options, &source)
      rescue StandardError
        nil
      end

      # The context of a custom value's formatted value: the custom value, its customized object's project and the
      # value as stored; nil when it is not a custom value
      def value_context_for(view, custom_value)
        return nil unless custom_value.respond_to?(:custom_field) && custom_value.respond_to?(:value)

        owner = custom_value.respond_to?(:customized) ? custom_value.customized : nil
        project = owner.respond_to?(:project) ? owner.project : nil
        project ||= view.instance_variable_get(:@project) if view
        Context.new(view: view, object: custom_value, attribute: :value, project: project, only_path: true,
                    origin: :custom_value) { Array(custom_value.value).join(', ') }
      rescue StandardError
        nil
      end

      # The pass over a custom value's formatted value: only its HTML (html_safe), only the link processors
      def process_value(html, context, link: link_processors)
        return html unless context && html.is_a?(String) && html.respond_to?(:html_safe?) && html.html_safe?

        process(html, context, link: link, text: [])
      end

      # The pass over one formatted text. link: and text: name other processors than the registered ones (a scenario's
      # check). A text with core's placeholders in it (NUL) is never parsed: they are back in place before the pass.
      def process(html, context, link: link_processors, text: text_processors)
        return html unless html.is_a?(String) && !html.empty? && !html.include?("\0")

        links = link.select { |p| active?(p, context) }
        texts = text.select { |p| active?(p, context) }
        return html if links.empty? && texts.empty?

        fragment = ::Loofah.html5_fragment(html)
        anchors = []
        runs = []
        collect(fragment, anchors, runs, false, false, false)
        changed = false
        anchors.each { |node, in_code| changed = true if run_links(node, in_code, links, context) } if links.any?
        runs.each { |node, in_link| changed = true if run_text(node, in_link, texts, context) } if texts.any?
        return html unless changed

        out = fragment.to_html
        html.respond_to?(:html_safe?) && html.html_safe? ? out.html_safe : out
      rescue StandardError => e
        log(e)
        html
      end

      private

      def active?(processor, context)
        !processor.respond_to?(:active?) || processor.active?(context)
      rescue StandardError => e
        log(e)
        false
      end

      # The links (with whether they stand in code) and the runs of text (with whether they stand in a link), in the
      # order of the text, before anything is changed
      def collect(node, anchors, runs, in_code, no_text, in_link)
        node.children.each do |child|
          if child.text?
            runs << [child, in_link] unless no_text || child.content.empty?
          elsif child.element?
            name = child.name.downcase
            is_link = name == 'a'
            anchors << [child, in_code] if is_link && child['href']
            collect(child, anchors, runs, in_code || CODE.include?(name), no_text || NO_TEXT.include?(name), in_link || is_link)
          end
        end
      end

      def run_links(node, in_code, processors, context)
        link = Link.new(node, kind_of(node['href']), in_code)
        processors.each do |p|
          p.call(link, context)
        rescue StandardError => e
          log(e)
        end
        link.changed?
      end

      # One run through the processors in turn; HTML that takes its place gives its own runs to the processors after
      def run_text(node, in_link, processors, context)
        processors.each_with_index do |p, i|
          next if node.parent.nil?

          out = begin
            p.call(TextRun.new(node.content, in_link), context)
          rescue StandardError => e
            log(e)
            nil
          end
          next if out.nil?

          parent = node.parent
          prev = node.previous_sibling
          stop = node.next_sibling
          node.replace(out.to_s)
          added = []
          cur = prev ? prev.next_sibling : parent.children.first
          while cur && cur != stop
            added << cur
            cur = cur.next_sibling
          end
          rest = processors[(i + 1)..]
          added.each { |n| run_text(n, in_link, rest, context) if n.text? && !n.content.empty? } if rest.any?
          return true
        end
        false
      end

      def log(error)
        return unless defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger

        ::Rails.logger.warn("[gk_core_stuff] formatting_processors: #{error.class}: #{error.message}")
      end
    end

    # Prepended on ApplicationHelper: the pass after core's textilizable, with the context read before core changes
    # the options
    module HelperPatch
      def textilizable(*args)
        context = FormattingProcessors.on? ? FormattingProcessors.context_for(self, args) : nil
        html = super
        context ? FormattingProcessors.process(html, context) : html
      end
    end

    # Prepended on Redmine::FieldFormat::Base: the pass after core has formatted a custom value as HTML
    module FieldValuePatch
      def formatted_custom_value(view, custom_value, html = false)
        out = super
        return out unless html && FormattingProcessors.values_on?

        FormattingProcessors.process_value(out, FormattingProcessors.value_context_for(view, custom_value))
      end
    end

    # The proposal's DSL on Redmine::Plugin, for as long as core has none
    module PluginDsl
      def formatting_processor(link: nil, text: nil)
        GkCoreStuff::FormattingProcessors.register(id, link: link, text: text)
      end
    end
  end

  # Always on, without a setting: other plugins hook their marks in formatted text into it, and with nothing registered
  # a text is not even parsed
  register :formatting_processors, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:formatting_processors) }, always: true do
    ::Redmine::Plugin.include(FormattingProcessors::PluginDsl) unless ::Redmine::Plugin.include?(FormattingProcessors::PluginDsl)
    ::ApplicationHelper.prepend(FormattingProcessors::HelperPatch) unless ::ApplicationHelper < FormattingProcessors::HelperPatch
  end

  # The custom values' pass, GK's own answer to the proposal's open question: always on for as long as core has no
  # pass over a custom value's formatted value (compat's formatting_processors_values), also when core has the registry
  # for formatted text, so that a Link value or a link pattern keeps rel and the look
  register :formatting_processors_values, issue: nil, defaults: {}, in_core: -> { GkCoreStuff.core_has?(:formatting_processors_values) }, always: true do
    unless ::Redmine::FieldFormat::Base < FormattingProcessors::FieldValuePatch
      ::Redmine::FieldFormat::Base.prepend(FormattingProcessors::FieldValuePatch)
    end
  end
end
