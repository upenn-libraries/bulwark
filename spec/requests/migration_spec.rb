# frozen_string_literal: true

RSpec.describe 'Migration Endpoints', type: :request do
  let(:repo) { FactoryBot.create :repo, :with_unique_identifier }

  describe 'GET migration#serialize' do
    it 'returns OK' do
      get serialize_path(CGI.escape(repo.unique_identifier)), format: :json
      expect(response).to have_http_status(200)
    end

    it 'returns 404 if repo not found' do
      get serialize_path('some-bogus-id'), format: :json
      expect(response).to have_http_status(404)
    end

    it 'returns 500 if error during object build' do
      allow_any_instance_of(MigrationObjectBuilder).to(
        receive(:build).and_raise(MigrationObjectBuilder::Error.new('Kaboom'))
      )
      get serialize_path(CGI.escape(repo.unique_identifier)), format: :json
      expect(response).to have_http_status(500)
      expect(JSON.parse(response.body)['exception']).to eq 'Kaboom'
    end
  end
end
