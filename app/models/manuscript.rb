class Manuscript < ActiveFedora::Base

  validates :title, presence: true
  validates :identifier, presence: true

  has_many :pages

  property :abstract, predicate: ::RDF::Vocab::DC.abstract, multiple: false do |index|
    index.as :stored_searchable
  end

  property :contributor, predicate: ::RDF::Vocab::DC.contributor, multiple: true do |index|
    index.as :stored_searchable
  end

  property :coverage, predicate: ::RDF::Vocab::DC.coverage, multiple: true do |index|
    index.as :stored_searchable
  end

  property :creator, predicate: ::RDF::Vocab::DC.creator, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :date, predicate: ::RDF::Vocab::DC.date, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :description, predicate: ::RDF::Vocab::DC.description, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :format, predicate: ::RDF::Vocab::DC.format, multiple: true do |index|
    index.as :stored_searchable
  end

  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: true do |index|
    index.as :stored_searchable
  end

  property :includes, predicate: ::RDF::Vocab::DC.hasPart, multiple: true do |index|
    index.as :stored_searchable
  end

  property :includesComponent, predicate: ::RDF::URI.new("http://library.upenn.edu/pqc/ns/includesComponent"), multiple: true do |index|
    index.as :stored_searchable
  end

  property :language, predicate: ::RDF::Vocab::DC.language, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :publisher, predicate: ::RDF::Vocab::DC.publisher, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :relation, predicate: ::RDF::Vocab::DC.relation, multiple: true do |index|
    index.as :stored_searchable
  end

  property :rights, predicate: ::RDF::Vocab::DC.rights, multiple: true do |index|
    index.as :displayable
  end

  property :source, predicate: ::RDF::Vocab::DC.source, multiple: true do |index|
    index.as :stored_searchable
  end

  property :subject, predicate: ::RDF::Vocab::DC.subject, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :title, predicate: ::RDF::Vocab::DC.title, multiple: true do |index|
    index.as :stored_searchable
  end

  property :item_type, predicate: ::RDF::Vocab::DC.type, multiple: true do |index|
    index.as :stored_searchable
  end

  property :file_list, predicate: ::RDF::URI.new("http://library.upenn.edu/pqc/ns/file_list") do |index|
    index.as :displayable
  end

  def init
    self.item_type ||= "Manuscript"
  end

##########
#
# Each content type should specify their own attach_files method
# leveraging the Utils::Process module's attach_file method to
# attach assets, and return an error message as a string if the asset
# does not exist
#
##########
  def attach_files(repo)
    Page.find(:parent_manuscript => self.id).each do |page|
      page.manuscript = self
      page.save!
      file_link = "#{repo.version_control_agent.working_path}/#{repo.assets_subdirectory}/#{page.file_name}"
      if File.exist?(file_link)
        Utils::Process.attach_file(repo, page, file_link, "pageImage")
      else
        return "No file at #{repo.assets_subdirectory}/#{page.file_name} detected, nothing attached."
      end
    end
  end


end
