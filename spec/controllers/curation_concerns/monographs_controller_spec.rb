require 'rails_helper'

describe CurationConcerns::MonographsController do
  let(:monograph) { create(:monograph, user: user, press: press.subdomain) }
  let(:press) { build(:press) }

  before do
    sign_in user
  end

  context 'a platform superadmin' do
    let(:user) { create(:platform_admin) }

    describe "#show" do
      it 'is successful' do
        get :show, id: monograph
        expect(response).to be_success
      end
    end

    describe "#create" do
      it 'is successful' do
        post :create, monograph: { title: ['Title one'],
                                   press: press.subdomain,
                                   date_published: ['Oct 20th'] }

        expect(assigns[:curation_concern].title).to eq ['Title one']
        expect(assigns[:curation_concern].date_published).to eq ['Oct 20th']
        expect(assigns[:curation_concern].press).to eq press.subdomain
        expect(response).to redirect_to Rails.application.routes.url_helpers.curation_concerns_monograph_path(assigns[:curation_concern])
      end
    end

    describe "#publish" do
      it 'is successful' do
        expect(PublishJob).to receive(:perform_later).with(monograph)
        post :publish, id: monograph
        expect(response).to redirect_to Rails.application.routes.url_helpers.curation_concerns_monograph_path(monograph)
        expect(flash[:notice]).to eq "Monograph is publishing."
      end
    end
  end # platform superadmin

  context 'a press-level admin' do
    let(:user) { create(:press_admin) }

    describe "#create" do
      context 'within my own press' do
        let(:press) { user.presses.first }

        it 'is successful' do
          expect {
            post :create, monograph: { title: ['Title one'],
                                       press: press.subdomain }
          }.to change { Monograph.count }.by(1)

          expect(assigns[:curation_concern].title).to eq ['Title one']
          expect(assigns[:curation_concern].press).to eq press.subdomain
          expect(response).to redirect_to Rails.application.routes.url_helpers.curation_concerns_monograph_path(assigns[:curation_concern])
        end
      end

      context "within a press that I don't have permission for" do
        it 'denies access' do
          expect {
            post :create, monograph: { title: ['Title one'],
                                       press: press.subdomain }
          }.not_to change { Monograph.count }

          expect(response.status).to eq 401
          expect(response).to render_template :unauthorized
        end
      end
    end
  end # press-level admin
end
