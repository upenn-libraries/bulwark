class ManuscriptForm
  include HydraEditor::Form

  self.model_class = Manuscript
  self.terms = ["abstract","contributor","coverage","creator","date","description","format","identifier","includes","includesComponent","language","publisher","relation","rights","source","subject","title","item_type"]
  self.required_fields = ["title","identifier","rights"]
end
