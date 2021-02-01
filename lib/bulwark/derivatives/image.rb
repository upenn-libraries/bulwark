# This class will eventually replace Utils::Derivatives.
module Bulwark
  module Derivatives
    module Image
      # Generates image derivative.
      #
      # @params original [String] location of file from which the derivative should be generated
      # @params write_to [String] location where derivative should be writen to, if directory generates filename from original file
      # @params width [Integer] width image should be resized to
      # @params height [Integer] height image should be resized to
      # @params format [String] format image should be in
      # @return [String] location of derivative
      def self.generate(original, write_to, width, height, format)
        raise Bulwark::Derivatives::Error, "#{write_to} does not exist" unless File.exist?(write_to)

        image = MiniMagick::Image.open(original)
        image.quality(90)
        image.resize("#{width}x#{height}")
        image.format(format)

        if File.directory?(write_to)
          write_to = File.join(write_to, "#{File.basename(original, '.*')}.#{format}").to_s
        end

        image.write(write_to)
        File.chmod(0644, write_to)
        write_to
      rescue => e
        # Raise new error with new message and original backtrace
        raise Bulwark::Derivatives::Error, "Error generating derivative for #{original}: #{e.class} #{e.message}", e.backtrace
      end

      # Generates thumbnail derivative.
      def self.thumbnail(original, write_to)
        generate(original, write_to, 200, 200, 'jpeg')
      end

      # Generates access copy derivative
      def self.access_copy(original, write_to)
        generate(original, write_to, '3500', '7000', 'jpeg')
      end
    end
  end
end
