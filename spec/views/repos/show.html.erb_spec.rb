require 'rails_helper'

RSpec.describe "repos/show", type: :view do
  before(:each) do
    @repo = assign(:repo, Repo.create!(
      :title => "Title",
      :purl => "Purl",
      :prefix => "Prefix",
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Purl/)
    expect(rendered).to match(/Prefix/)
    expect(rendered).to match(/Description/)
  end
end
