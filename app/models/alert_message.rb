# frozen_string_literal: true

class AlertMessage < ActiveRecord::Base
  # Locations where the message is displayed
  LOCATIONS = %w[header home].freeze

  # Level - corresponding to bootstrap alert class - for the message
  LEVELS = %w[info warning danger].freeze

  # require message content if message is active
  validates :message, presence: true, if: :active?

  validates :location, inclusion: { in: LOCATIONS }
  validates :level, inclusion: { in: LEVELS }

  # @return [AlertMessage]
  def self.header
    find_by(location: 'header')
  end

  # @return [AlertMessage]
  def self.home
    find_by(location: 'home')
  end
end
