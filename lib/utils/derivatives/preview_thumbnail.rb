module Utils
  module Derivatives
    module PreviewThumbnail
      extend self
      def generate_copy(file, destination)
        Utils::Derivatives.generate_copy(file, destination, :type => 'preview_thumbnail')
      end
    end
  end
end
