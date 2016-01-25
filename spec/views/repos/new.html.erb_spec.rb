require 'rails_helper'

RSpec.describe "repos/new", type: :view do
  before(:each) do
    assign(:repo, Repo.new(
      :title => "MyString",
      :purl => "MyString",
      :prefix => "MyString",
      :description => "MyString"
    ))
  end

  it "renders new repo form" do
    render

    assert_select "form[action=?][method=?]", repos_path, "post" do

      assert_select "input#repo_title[name=?]", "repo[title]"

      assert_select "input#repo_purl[name=?]", "repo[purl]"

      assert_select "input#repo_prefix[name=?]", "repo[prefix]"

      assert_select "input#repo_description[name=?]", "repo[description]"
    end
  end
end
