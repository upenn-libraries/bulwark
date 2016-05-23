class MetadataSource < ActiveRecord::Base

  belongs_to :metadata_builder, :foreign_key => "metadata_builder_id"

  include Utils

  serialize :original_mappings
  serialize :user_defined_mappings
  serialize :children

  def path
    read_attribute(:path) || ''
  end

  def type
    read_attribute(:type) || ''
  end

  def num_objects
    read_attribute(:num_objects) || ''
  end

  def x_start
    read_attribute(:x_start) || ''
  end

  def y_start
    read_attribute(:y_start) || ''
  end

  def x_stop
    read_attribute(:x_stop) || ''
  end

  def y_stop
    read_attribute(:y_stop) || ''
  end

  def root_element
    read_attribute(:root_element) || ''
  end

  def parent_element
    read_attribute(:parent_element) || ''
  end

  def children
    read_attribute(:children) || ''
  end

  def children=(children)
    self[:children] = children.reject(&:empty?)
  end

  def original_mappings
    read_attribute(:original_mappings) || ''
  end

  def user_defined_mappings
    read_attribute(:user_defined_mappings) || ''
  end

  def user_defined_mappings=(user_defined_mappings)
    self[:user_defined_mappings] = eval(user_defined_mappings)
  end

  def set_metadata_mappings
    self.metadata_builder.repo.version_control_agent.clone
    self.original_mappings = convert_metadata
    self.metadata_builder.repo.version_control_agent.delete_clone
    self.save!
  end

  private

    def convert_metadata
      begin
        pathname = Pathname.new(self.path)
        ext = pathname.extname.to_s[1..-1]
        case ext
        when "xlsx"
          self.metadata_builder.repo.version_control_agent.get(:get_location => "#{self.path}")
          @mappings = generate_mapping_options_xlsx(self)
        else
          raise "Illegal metadata source unit type"
        end
        return @mappings
      rescue
        raise $!, "Metadata conversion failed due to the following error(s): #{$!}", $!.backtrace
      end
    end

    def generate_mapping_options_xlsx(source)
      mappings = {}
      headers = []
      iterator = 0
      x_start, y_start, x_stop, y_stop = offset
      workbook = RubyXL::Parser.parse(self.path)
      case self.view_type
      when "horizontal"
        while((x_stop >= (x_start+iterator)) && (workbook[0][y_start][x_start+iterator].present?))
          header = workbook[0][y_start][x_start+iterator].value
          headers << header
          vals = []
          #This variable could be user-defined in order to let the user set the values offset
          vals_iterator = 1
          while(workbook[0][y_start+vals_iterator].present? && workbook[0][y_start+vals_iterator][x_start+iterator].present?) do
            vals << workbook[0][y_start+vals_iterator][x_start+iterator].value
            vals_iterator += 1
          end
          mappings[header] = vals
          iterator += 1
        end
      when "vertical"
        while((y_stop >= (y_start+iterator)) && (workbook[0][y_start+iterator].present?))
          header = workbook[0][y_start+iterator][x_start].value
          headers << header
          vals = []
          vals_iterator = 1
          while(workbook[0][y_start+iterator].present? && workbook[0][y_start+iterator][x_start+vals_iterator].present?) do
            vals << workbook[0][y_start+iterator][x_start+vals_iterator].value
            vals_iterator += 1
          end
          mappings[header] = vals
          iterator += 1
        end
      else
        raise "Illegal source type #{self.view_type} for #{self.path}"
      end
      return mappings
    end

    def offset
      x_start = self.x_start - 1
      y_start = self.y_start - 1
      x_stop = self.x_stop - 1
      y_stop = self.y_stop - 1
      return x_start, y_start, x_stop, y_stop
    end

end
