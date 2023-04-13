# frozen_string_literal: true

RSpec.describe 'Migration Endpoints', type: :request do
  let(:repo) { FactoryBot.create :repo, :with_unique_identifier }

  describe "GET migration#serialize" do
    it 'returns OK' do
      get serialize_path(CGI.escape(repo.unique_identifier)), format: :json
      expect(response).to have_http_status(200)
    end
  end
end
