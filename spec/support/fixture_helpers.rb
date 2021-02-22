# frozen_string_literal: true

module FixtureHelpers
  def fixture(*path)
    File.join(fixture_path, *path)
  end

  def fixture_to_str(*path)
    File.read(fixture(path))
  end

  def fixture_to_xml(*path)
    Nokogiri::XML(fixture_to_str(*path))
  end
end
