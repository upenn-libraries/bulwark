module Utils
  module Derivatives
    module Thumbnail
      extend self
      def generate_copy(filename, file = '', destination)
        Utils::Derivatives.generate_copy(filename, file, destination, :type => 'thumbnail')
      end
    end
  end
end
