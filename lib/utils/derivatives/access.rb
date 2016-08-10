module Utils
  module Derivatives
    module Access
      extend self
      def generate_copy(file, destination)
        file_path = Utils::Derivatives.generate_copy(file, destination, :type => "access")
        return file_path
      end
    end
  end
end
