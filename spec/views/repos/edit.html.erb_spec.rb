require 'rails_helper'

RSpec.describe "repos/edit", type: :view do
  before(:each) do
    @repo = assign(:repo, Repo.create!(
      :title => "MyString",
      :purl => "MyString",
      :prefix => "MyString",
      :description => "MyString"
    ))
  end

  it "renders the edit repo form" do
    render

    assert_select "form[action=?][method=?]", repo_path(@repo), "post" do

      assert_select "input#repo_title[name=?]", "repo[title]"

      assert_select "input#repo_purl[name=?]", "repo[purl]"

      assert_select "input#repo_prefix[name=?]", "repo[prefix]"

      assert_select "input#repo_description[name=?]", "repo[description]"
    end
  end
end
