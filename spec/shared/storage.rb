
# Cleaning up storage directories.
#
# FIXME: Temporary solution until Repos can clean up after themselves when they are destroyed.
shared_context 'cleanup test storage' do
  after do
    FileUtils.chmod_R(0755, Rails.root.join('tmp', 'test_storage'))
    FileUtils.rm_r(Dir.glob(Rails.root.join('tmp', 'test_storage', 'data', '*')))
    FileUtils.rm_r(Dir.glob(Rails.root.join('tmp', 'test_storage', 'scratch', '*')))
    FileUtils.rm_r(Dir.glob(Rails.root.join('tmp', 'test_storage', 'special_remote', '*')))
  end
end
