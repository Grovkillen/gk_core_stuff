# frozen_string_literal: true

module GkCoreStuff
  # single_preference.
  # Found 2026-10-05: basic stopped on a new instance because Isak had two rows in user_preferences (7 with his choice,
  # 8 without), and Redmine read the one he had not saved. Core's User#pref builds a new row whenever the user object
  # holds no preference (`self.preference ||= UserPreference.new(user: self)`), also when its association was read
  # earlier as empty and another object has saved one since; the index on user_id is not unique, so nothing stops the
  # second row, and has_one reads the rows in no stated order, so which one is read is up to the database (any
  # database) and can change from one read to the next. A user then loses what was saved in the other row without any
  # error.
  # The module, written as a core candidate:
  # * User#pref asks the database before it builds a new row, and reads the oldest row (a stated order);
  # * rows found beyond one are merged into the oldest: its columns kept, the others' `others` keys added where it
  #   lacks them and the newer row's value taken where both have the key (the newer row was written last), and the
  #   extra rows removed. A preference is a setting, not a record (P1 is about records).
  # Off: core's own behaviour.
  module SinglePreference
    module_function

    def on? = GkCoreStuff.on?(:single_preference)

    # The preference of a saved user, the oldest row; extra rows merged into it
    def for_user(user_id)
      rows = ::UserPreference.where(user_id: user_id).order(:id).to_a
      return rows.first if rows.size <= 1

      merge!(rows)
    end

    def merge!(rows)
      keep = rows.first
      others = (keep.others || {}).to_h.dup
      rows.drop(1).each do |r|
        (r.others || {}).to_h.each { |k, v| others[k] = v unless v.nil? }
      end
      ::UserPreference.transaction do
        keep.others = others
        keep.save!(validate: false)
        ::UserPreference.where(id: rows.drop(1).map(&:id)).delete_all
      end
      Rails.logger.warn("[gk_core_stuff] user #{keep.user_id}: #{rows.size} preference rows merged into #{keep.id}")
      keep
    end

    module UserPatch
      def pref
        if SinglePreference.on? && persisted?
          assoc = association(:preference)
          # read by the module once per object: not loaded yet, or loaded as empty (perhaps saved since by another)
          if !assoc.loaded? || assoc.target.nil?
            found = SinglePreference.for_user(id)
            assoc.target = found if found
          end
        end
        super
      end
    end
  end

  register :single_preference, issue: nil, defaults: { 'single_preference' => '1' }, in_core: -> { false } do
    ::User.prepend(SinglePreference::UserPatch) unless ::User < SinglePreference::UserPatch
  end
end
