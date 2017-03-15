require 'jhove_service'

module Utils
  module Artifacts
    module Metadata
      module Preservation
        class Jhove

          attr_accessor :directory, :target, :filename

          def initialize(directory, target = nil)
            @directory = directory || nil
            @target = target
            @filename = 'jhove_output.xml' #default when using jhove_service
          end

          def characterize
            if File.exist?(directory)
              jhove = JhoveService.new(directory)
              jhove.run_jhove(directory)
            end
            if target.present? && File.exist?(target)
              FileUtils.move("#{directory}/#{filename}", "#{target}/#{filename}")
            end
          end

        end
      end
    end
  end
end