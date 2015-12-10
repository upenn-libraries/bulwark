class ManuscriptForm
  include HydraEditor::Form
  self.model_class = Manuscript
  self.terms = [title, origin, description] # Terms to be edited
  self.required_fields = [title] # Required fields
end
