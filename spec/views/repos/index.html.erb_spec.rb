require 'rails_helper'

RSpec.describe "repos/index", type: :view do
  before(:each) do
    assign(:repos, [
      Repo.create!(
        :title => "Title",
        :purl => "Purl",
        :prefix => "Prefix",
        :description => "Description"
      ),
      Repo.create!(
        :title => "Title",
        :purl => "Purl",
        :prefix => "Prefix",
        :description => "Description"
      )
    ])
  end

  it "renders a list of repos" do
    render
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "Purl".to_s, :count => 2
    assert_select "tr>td", :text => "Prefix".to_s, :count => 2
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
