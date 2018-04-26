module Utils
  module Derivatives
    module Access
      extend self
      def generate_copy(filename, file = '', destination)
        Utils::Derivatives.generate_copy(filename, file, destination, :type => 'access')
      end
    end
  end
end
