module Utils
  module Derivatives
    module Preview
      extend self
      def generate_copy(filename, file = '', destination)
        Utils::Derivatives.generate_copy(filename, file, destination, :type => 'preview')
      end
    end
  end
end
