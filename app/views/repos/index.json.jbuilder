json.array!(@repos) do |repo|
  json.extract! repo, :id, :title, :purl, :prefix, :description
  json.url repo_url(repo, format: :json)
end
