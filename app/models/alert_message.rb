# frozen_string_literal: true

class AlertMessage < ActiveRecord::Base
  # Locations where the message is displayed
  LOCATIONS = %w[header home].freeze

  # Level - corresponding to bootstrap alert class - for the message
  LEVELS = %w[warning info danger].freeze

  validates :message, presence: true

  with_options if: :display_date_provided? do
    validates :display_on, presence: true
    validates :display_until, presence: true
  end

  # TODO: validate only one active message per area?

  # @return [TrueClass, FalseClass]
  def display?
    return false unless active?

    Time.zone.now.between? display_on, display_until
  end

  private

    def display_date_provided?
      display_on || display_until
    end
end
