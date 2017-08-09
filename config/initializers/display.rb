module Display
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  private

  def config_yaml
    config_file = Rails.root.join('config', 'display.yml')
    fail "Missing configuration file at: #{config_file}." unless File.exist?(config_file)
    YAML.load(ERB.new(File.read(config_file)).result)[Rails.env]
  end

  module_function :config, :config_yaml
end
