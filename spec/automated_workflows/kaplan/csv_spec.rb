require 'rails_helper'

RSpec.describe AutomatedWorkflows::Kaplan::Csv do
  describe '.generate_repo' do
    include_context 'manifest csv for object one'
    include_context 'cleanup test storage'

    let(:repo) { Repo.find_by(unique_identifier: ark) }

    before do
      AutomatedWorkflows::Kaplan::Csv.generate_repos(csv_filepath)
    end

    it 'creates db record' do
      expect(Repo.find_by(unique_identifier: ark)).not_to be nil
    end

    it 'adds correct asset endpoint to db record' do
      asset_endpoint = repo.endpoint.find_by(content_type: 'assets')
      expect(asset_endpoint.source).to eq Rails.root.join(AutomatedWorkflows.config['kaplan']['csv']['nonstandard']['test']['endpoint'], 'object_one/').to_s
      expect(asset_endpoint.destination).to eql 'data/assets'
    end

    it 'adds correct metadata endpoint to db record' do
      metadata_endpoint = repo.endpoint.find_by(content_type: 'metadata')
      expect(metadata_endpoint.source).to eq Rails.root.join(AutomatedWorkflows.config['kaplan']['csv']['nonstandard']['test']['endpoint'], 'object_one/').to_s
      expect(metadata_endpoint.destination).to eq 'data/metadata'
    end

    it 'creates git repository' do
      expect(File.exist?(repo.version_control_agent.remote_path)).to be true
    end
  end
end
