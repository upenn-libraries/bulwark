module Utils
  module Derivatives
    module Preview
      extend self
      def generate_copy(file, destination)
        Utils::Derivatives.generate_copy(file, destination, :type => 'preview')
      end
    end
  end
end
