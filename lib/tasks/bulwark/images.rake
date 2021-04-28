# frozen_string_literal: true
namespace :bulwark do
  namespace :images do
    # TODO: Eventually this could be part of the import process.
    desc 'Checks to see if any images in the directory are detected as corrupt via ImageMagick'
    task check_for_corruption: :environment do
      drive = ENV['drive']
      path = ENV['path']

      abort(Rainbow('Incorrect arguments. Pass drive=drive_name and path=directory/with/files').red) if drive.blank? || path.blank?

      dir_path = File.join(Bulwark::Import::MountedDrives.path_to(drive), path, '*')

      Dir.glob(dir_path).sort.each do |filepath|
        next unless ['.tif', '.tiff', '.jpeg', '.jpg'].include?(File.extname(filepath).downcase)

        begin
          image = MiniMagick::Image.open(filepath)
          image.identify(&:verbose)
        rescue
          puts Rainbow("#{filepath}: Corrupt").red
        else
          puts Rainbow("#{filepath}: Valid").green
        end
      end
    end
  end
end
