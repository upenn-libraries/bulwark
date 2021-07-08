# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertMessage, type: :model do

  context 'basic attributes' do
    let(:alert_message) { FactoryBot.create(:alert_message) }

    it 'has an active boolean that defaults to false' do
      expect(alert_message.active?).to be false
    end

    it 'has a location' do
      expect(alert_message.location).to be_in AlertMessage::LOCATIONS
    end

    it 'has a level' do
      expect(alert_message.level).to be_in AlertMessage::LEVELS
    end

    describe '#display?' do
      it 'returns false if active is false' do
        expect(alert_message.display?).to be false
      end
    end
  end

  context 'display range dates' do
    # let! used here to ensure the generated timespan isn't impacted by the stub of Time below
    let!(:alert_message) { FactoryBot.create(:alert_message, :date_limited, :active) }

    it 'has a display_on date' do
      expect(alert_message.display_on).to be_a Time
    end

    it 'has a display_until date' do
      expect(alert_message.display_until).to be_a Time
    end

    describe '#display?' do
      context 'with active set to true' do
        it 'returns false if the current time is outside of the defined range' do
          expect(alert_message.display?).to be false
        end

        it 'returns true if the current time is inside the defined range' do
          allow(Time).to receive(:now).and_return(Time.zone.now + 2.days)
          expect(alert_message.display?).to be true
        end
      end
    end
  end

  context 'validations' do
    it 'requires a display_on if a display_until is set' do
      alert_message = FactoryBot.build(:alert_message, :active, display_until: Time.zone.now).valid?
      expect(alert_message.errors).to include :display_on
    end

    it 'requires a display_until if a display_on is set' do
      alert_message = FactoryBot.build(:alert_message, :active, display_on: Time.zone.now).valid?
      expect(alert_message.errors).to include :display_until
    end
  end
end
