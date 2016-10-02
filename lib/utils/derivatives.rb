module Utils
  module Derivatives

    extend self

    def generate_copy(file, directory, options = {})
      begin
        copy_type = options[:type] || 'default'
        width = Utils::Derivatives::Constants::COPY_TYPES[copy_type][:width]
        height = Utils::Derivatives::Constants::COPY_TYPES[copy_type][:height]
        extension = Utils::Derivatives::Constants::COPY_TYPES[copy_type][:extension]
        image = MiniMagick::Image.open(file)
        image.resize "#{width}x#{height}"
        image.format "#{extension}"
        fname = "#{options[:type]}#{image.signature}.#{extension}"
        fpath = Digest::MD5.hexdigest(fname).scan(/.../)[0..2].join('/')
        derivative_link = "#{directory}/#{fpath}/#{fname}"
        FileUtils::mkdir_p "#{directory}/#{fpath}"
        image.write(derivative_link)
        return "#{fpath}/#{fname}"
      rescue
        return
      end
    end

  end
end
