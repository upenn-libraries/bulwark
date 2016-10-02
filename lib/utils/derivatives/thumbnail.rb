module Utils
  module Derivatives
    module Thumbnail
      extend self
      def generate_copy(file, destination)
        Utils::Derivatives.generate_copy(file, destination, :type => 'thumbnail')
      end
    end
  end
end
