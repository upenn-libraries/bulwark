
# Shared context that provides a mocked EZID generation for a Repo.
shared_context 'stub successful EZID requests' do
  before do
    # Stub request to mint ezids
    stub_request(:post, "https://#{Ezid::Client.config.host}/shoulder/#{Ezid::Client.config.default_shoulder}")
      .with(
        basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
      )
      .to_return(
        status: 201,
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' } ,
        body: "success: #{Ezid::Client.config.default_shoulder}#{SecureRandom.hex(4)}"
      )

      # Stub request to update ezids
      stub_request(:post, /#{Ezid::Client.config.host}\/id\/.*/)
        .with(
          basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
          headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
        )
        .to_return { |request|
          {
            status: 200,
            headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
            body: "success: #{request.uri.path.split('/', 3).last}"
          }
        }
  end
end
