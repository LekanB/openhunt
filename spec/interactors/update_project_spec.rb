
require 'rails_helper'

RSpec.describe UpdateProject do
  let(:submitter) { FactoryGirl.create(:user) }
  let(:project) { submitter.projects.create(FactoryGirl.attributes_for(:project)) }
  before :each do
    DatabaseCleaner.clean
  end
  it "updates trivial url change" do
    params = { url: "http://asdf.com" }
    UpdateProject.call(params: params, project: project, user: submitter)
    expect(project.reload.url).to eql "http://asdf.com"
  end
  it "updates the name" do
    params = { name: "banana" }
    UpdateProject.call(params: params, project: project, user: submitter)
    expect(project.reload.name).to eql "banana"
  end
  it "updates the description" do
    params = { description: "banana" }
    UpdateProject.call(params: params, project: project, user: submitter)
    expect(project.reload.description).to eql "banana"
  end
  it "leaves an audit log" do
    submitter.update_attributes(moderator: true)
    params = { description: "banana" }
    UpdateProject.call(params: params, project: project, user: submitter)
    expect(AuditLog.first.item_type).to eql "update_project"
    expect(AuditLog.first.target_url).to eql "/detail/asdf"
  end

  context "protections" do
    it "only allows owner or moderator" do
      bad_user = FactoryGirl.create(:user)
      params = { name: "pwn u!" }
      result = UpdateProject.call(params: params, project: project, user: bad_user)
      expect(result.success?).to eql false
    end
    it "doesn't update to use another project's url" do
      project
      other_project = submitter.projects.create(FactoryGirl.attributes_for(:project, url: "http://this_url_ok.com"))
      params = { url: "http://asdf.com"}
      result = UpdateProject.call(params: params, project: other_project, user: submitter)
      expect(result.success?).to eql false
    end
  end
end
