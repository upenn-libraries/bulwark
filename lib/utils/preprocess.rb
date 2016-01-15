module Utils
  module Preprocess

    def initialize
    end

    extend self

    def generate_manifests(final_root_path)
      build(Utils::Manifests::Checksum, final_root_path)
    end


    private

    def build(type, path)
      set_contents = "blah"
      manifest = Utils::Manifests::Manifest.new(type, path, set_contents)
      manifest.save
    end

    def get_contents(obj)

    end

    def set_contents(type, contents)

    end

  end
end
