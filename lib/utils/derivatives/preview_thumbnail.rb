module Utils
  module Derivatives
    module PreviewThumbnail
      extend self
      def generate_copy(filename, file = '', destination)
        Utils::Derivatives.generate_copy(filename, file, destination, :type => 'preview_thumbnail')
      end
    end
  end
end
