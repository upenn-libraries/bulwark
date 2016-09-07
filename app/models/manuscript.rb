class Manuscript < ActiveFedora::Base
  include Hydra::Works::WorkBehavior

  has_many :pages

  contains "thumbnail"

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
    pages = Page.where(:parent_manuscript => self.id)
    pages.each do |page|
      if page.file_name.present?
        Utils::Process.attach_file(repo, page, page.file_name, "pageImage")
        self.members << page
      end
    end
    pages_sorted = pages.to_a.sort_by! { |p| p.page_number }
    pages_sorted.each do |page|
      display_values = {}
      file_print = page.pageImage.uri
      repo.images_to_render[file_print.to_s.html_safe] = page.serialized_attributes
    end
    self.save
  end

  def thumbnail_link
    self.thumbnail.ldp_source.subject
  end

  def cover
    Page.where(:parent_manuscript => self.id).sort_by {|obj| obj.page_number}.first
  end


end
