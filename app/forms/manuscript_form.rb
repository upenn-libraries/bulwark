class ManuscriptForm
  include HydraEditor::Form
  include HydraEditor::Form::Permissions

  self.model_class = Manuscript
  self.terms = ["title","creator","date","description","item_type","subject","collection","identifier","location","rights"] # Terms to be edited
  self.required_fields = ["title","identifier","rights"] # Required fields
end
