
# Shared context that provides a manifest CSV to load one object.
shared_context 'manifest csv for object one' do
  let(:manifest) do
    <<~MANIFEST
      share,path,unique_identifier,timestamp,directive_name,status
      test,object_one,#{ark},,"#{name}",
    MANIFEST
  end
  let(:ark) { 'ark:/99999/fk4th9vh1c' }
  let(:name) { 'Object One' }
  let(:csv_filepath) do
    filepath = Rails.root.join('tmp', 'manifest.csv').to_s
    File.open(filepath, 'w') { |f| f.write(manifest) }
    filepath
  end

  after { File.delete(csv_filepath) }
end
