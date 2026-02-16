# frozen_string_literal: true

module Analytics
  class StatNotFoundError < StandardError; end

  class Stat
    include ActiveModel::Model
    include ActiveModel::Attributes

    COUNTERS = {
      active_licensed_users: Counters::ActiveLicensedUsers,
      machines: Counters::Machines,
      licenses: Counters::Licenses,
      users: Counters::Users,
      alus: Counters::ActiveLicensedUsers, # alias
    }

    attribute :account, default: -> { Current.account }
    attribute :environment, default: -> { Current.environment }

    validates :account, presence: true

    def initialize(counter_name, **)
      @counter_name = counter_name.to_s.underscore.to_sym

      raise StatNotFoundError, "invalid stat: #{@counter_name.inspect}" unless
        COUNTERS.key?(@counter_name)

      super(**)
    end

    def count
      @count ||= counter.count
    end

    def as_json(*) = { count: }

    private

    attr_reader :counter_name

    def counter_class = COUNTERS[counter_name]
    def counter       = counter_class.new(account:, environment:)
  end
end
