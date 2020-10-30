module Utils
  module Derivatives
    extend self

    def generate_copy(file, image, directory, options = {})
      begin
        image = MiniMagick::Image.open(file) unless image.present?
        copy_type = options[:type] || 'default'
        width = Utils::Derivatives::Constants::COPY_TYPES[copy_type][:width]
        height = Utils::Derivatives::Constants::COPY_TYPES[copy_type][:height]
        extension = Utils::Derivatives::Constants::COPY_TYPES[copy_type][:extension]
        quality = Utils::Derivatives::Constants::COPY_TYPES[copy_type][:quality]
        image.quality quality
        image.resize "#{width}x#{height}"
        image.format "#{extension}"
        relative_path = determine_custom_file_path(copy_type, file, extension)
        derivative_path = relative_path.present? ? "#{directory}/#{relative_path}" : "#{directory}/#{Digest::MD5.hexdigest("#{copy_type}#{image.signature}.#{extension}").scan(/.../)[0..2].join('/')}"
        FileUtils::mkdir_p "#{relative_path.present? ? derivative_path.gsub(relative_path,'') : derivative_path}"
        write_path = "#{relative_path.present? ? derivative_path : "#{derivative_path}/#{copy_type}#{image.signature}.#{extension}"}"
        image.write(write_path)
        File.chmod(0644, write_path)
        return "#{derivative_path}/#{copy_type}#{image.signature}.#{extension}".gsub("#{directory}/",'')
      rescue => e
        # Raise new error with new message and original backtrace
        raise Bulwark::DerivativeGenerationError, "Error generating derivative for #{file}: ${e.class} ${e.message}", e.backtrace
      end
    end

    def determine_custom_file_path(copy_type, file, extension)
      return "#{File.basename(file)}.#{extension}" if copy_type == 'preview'
      return "#{File.basename(file)}.thumb.#{extension}" if copy_type == 'preview_thumbnail'
      return nil
    end

  end
end
