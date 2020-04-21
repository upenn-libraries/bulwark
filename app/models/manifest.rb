class Manifest < ActiveRecord::Base

  before_create :set_defaults
  serialize :last_action_performed, Hash
  serialize :validation_problems, Hash
  serialize :steps, Hash

  def validation_problems?
    !self.validation_problems.values.all?(&:empty?)
  end

  def uploaded_file
    @uploaded_file
  end

  def uploaded_file=(value)
    @uploaded_file = value
  end

  def unique_identifier
    "#{self.model_name}_#{self.id}"
  end

  def unique_shares
    manifest = CSV.parse(self.content)
    
    # Remove header row
    manifest.shift

    manifest.map do |row| row[0] end .uniq
  end

  def unique_identifiers
    manifest = CSV.parse(self.content)

    # Remove header row
    manifest.shift

    # unique identifier is in the third column for Kaplan manifests
    manifest.map do |row| row[2] end
  end

  def unique_identifiers_by_share(share = nil)
    manifest = CSV.parse(self.content)

    # Remove header row
    manifest.shift

    shares = share.nil? ? unique_shares : [share]
    result = {}
    shares.each do |share|
      # share is in the first column for Kaplan manifests
      # unique identifier is in the third column for Kaplan manifests
      result[share] = manifest.select do |row| share.nil? || row[0] == share end .map do |r| r[2] end
    end

    result
  end

  def set_defaults
    self.owner = User.current
    self.name = uploaded_file.original_filename
    self.content = uploaded_file.tempfile.read
    self.steps = {}
    self.validation_problems = {}
  end

  def update_steps(task)
    self.steps[task] = true
    self.save!
  end

  def update_last_action(update_string)
    self.last_action_performed = { :description => update_string }
    self.save!
  end

  def validate_manifest
    self.update_steps(:validate_manifest)

    manifest = CSV.parse(self.content)

    # Remove header row
    manifest.shift

    paths = manifest.map { |row| row[1] }
    arks = manifest.map { |row| row[2] } .select &:present?
    directives = manifest.map do |row| row[4] end
    manifest_gits = directives.map(&:gitify)
    colenda_map = Repo.pluck(:human_readable_name).map {|name| [name, name.gitify] }

    validation_problems[:duplicate_paths] = paths.select { |path| paths.count(path) > 1 } .uniq
    validation_problems[:duplicate_arks] = arks.select { |ark| arks.count(ark) > 1 } .uniq
    validation_problems[:duplicate_directives] = directives.select { |ark| directives.count(ark) > 1 } .uniq

    # Arks already in Colenda
    validation_problems[:existing_arks] = Repo.where(:unique_identifier => arks).pluck(:unique_identifier)

    # Directives already in Colenda
    validation_problems[:existing_directives] = Repo.where(:human_readable_name => directives).pluck(:human_readable_name)

    # Directive conflicts with existing repos in Colenda
    validation_problems[:git_conflicts] = colenda_map.select do |name,git| manifest_gits.member?(git) end .map(&:first)

    validation_problems[:unminted_arks] = arks.map do |ark| ark_exists?(ark) end .reject &:nil?

    self.validation_problems = validation_problems
    self.save!

    self.update_last_action(action_description[:validate_manifest])
  end

  def create_repos
    self.update_steps(:create_repos)

    csv_file = Tempfile.new
    begin
      csv_file.write(self.content)
      csv_file.close

      a = AutomatedWorkflows::Kaplan::Csv.generate_repos(csv_file.path)
      update_manifest(a) unless has_all_identifiers?
    ensure
      csv_file.unlink
    end

    self.update_last_action(action_description[:create_repos])
  end

  def process_manifest
    self.update_steps(:process_manifest)

    arks_by_share = self.unique_identifiers_by_share

    arks_by_share.each do |share, arks|
      agent = AutomatedWorkflows::Agent.new(AutomatedWorkflows::Kaplan, arks, AutomatedWorkflows::Kaplan::Csv.config.endpoint(share), :steps_to_skip => ['ingest'])
      agent.proceed
    end

    self.update_last_action(action_description[:process_manifest])
  end

  def repos_with_endpoint_problems
    repos = Repo.where(:unique_identifier => self.unique_identifiers)

    result = Hash.new { |hash, key| hash[key.unique_identifier] = key.endpoint.map(&:problems).reject(&:empty?).uniq }
    repos.each do |repo| result[repo] end
    result.reject do |k,v| v.empty? end
  end

  def repos_with_problem_files
    repos = Repo.where(:unique_identifier => self.unique_identifiers)

    result = Hash.new { |hash, key| hash[{:id => key.id, :unique_identifier => key.unique_identifier}] = key.problem_files }
    repos.each do |repo| result[repo] end
    result.reject do |k,v| v.empty? end
  end

  private

  def ark_exists?(ark)
    begin
      Ezid::Identifier.find(ark)
    rescue Exception => e
      return ark
    end

    return nil
  end

  def has_all_identifiers?
    manifest = CSV.parse(self.content)
    manifest.shift
    !(manifest.map do |r| r[2] end .any?(&:nil?))
  end

  def update_manifest(ids)
    manifest = CSV.parse(self.content)
    ids.each_with_index do |id, i|
      manifest[i+1][2] = id
    end
    self.content = manifest.map do |r| CSV.generate_line(r) end .join('')
    self.save!
  end

  def action_description
    { :validate_manifest => 'Manifest validated',
      :create_repos => 'Repositories created',
      :process_manifest => 'Manifest processed' }
  end

end
