class ManuscriptForm
  include HydraEditor::Form
  include HydraEditor::Form::Permissions

  self.model_class = Manuscript
  self.terms = ["abstract","contributor","coverage","creator","date","description","format","identifier","includes","includesComponent","language","publisher","relation","rights","source","subject","title","type"]
  self.required_fields = ["title","identifier","rights"]
end
