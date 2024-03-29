# frozen_string_literal: true
namespace :bulwark do
  namespace :images do
    # TODO: Eventually this could be part of the import process.
    desc 'Checks to see if any images in the directory are detected as corrupt via Vips'
    task check_for_corruption: :environment do
      path = ENV['path']

      abort(Rainbow('Incorrect arguments. Pass path=directory/with/files').red) if path.blank?

      dir_path = File.join(path, '*')

      Dir.glob(dir_path).sort.each do |filepath|
        next unless ['.tif', '.tiff', '.jpeg', '.jpg'].include?(File.extname(filepath).downcase)

        if ImageProcessing::Vips.valid_image?(File.new(filepath))
          puts Rainbow("#{filepath}: Valid").green
        else
          puts Rainbow("#{filepath}: Corrupt").red
        end
      end
    end

    # Used to test derivative generation.
    desc 'Generate derivatives for all files in directory'
    task generate_derivatives: :environment do
      directory = ENV['directory']

      abort(Rainbow('Incorrect arguments. Pass directory=directory/with/files').red) if directory.blank?

      # Can optionally specify access and thumbnail directory
      access_directory = ENV['access_directory'] || File.join(directory, 'access')
      thumbnail_directory = ENV['thumbnail_directory'] || File.join(directory, 'thumbnails')

      # Create thumbnail and access directory
      FileUtils.mkdir_p(access_directory)
      FileUtils.mkdir_p(thumbnail_directory)

      Dir.glob(File.join(directory, '*.{tif,tiff,jpeg}')).each do |filepath|
        begin
          access_time = Benchmark.measure { Bulwark::Derivatives::Image.access_copy(filepath, access_directory) }
          thumbnail_time = Benchmark.measure { Bulwark::Derivatives::Image.thumbnail(filepath, thumbnail_directory) }

          puts Rainbow("#{filepath}\taccess_copy: #{access_time.real}seconds\tthumbnail: #{thumbnail_time
                                                                                             .real}seconds").green
        rescue Bulwark::Derivatives::Error
          puts Rainbow("#{filepath} ERROR").red
        end
      end
    end
  end
end
