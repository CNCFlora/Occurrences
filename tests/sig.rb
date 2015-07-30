
require_relative 'base.rb'

describe "Test GIS forms" do

    before (:each) do 
      before_each() 
      login_before_each()
      upload()
    end

    after (:each) do after_each() end

    it "Do not show sig forms for non analysts" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/cncflora_test/specie/Aphelandra+longiflora"
      follow_redirect!

      expect(last_response.body).not_to have_tag('form.sig')
    end

    it "Do show gis forms for analysts" do
      get "/cncflora_test/specie/Aphelandra+longiflora"
      follow_redirect!

      expect(last_response.body).to have_tag('form.sig')
    end

    it "Edit field with analysis forms" do
      id1 = 'urn:occurrence:UNICAMP:UEC:10137'

      post "/cncflora_test/occurrences/#{id1}/sig?q=Aphelandra+longiflora",{:comment=>"Working form."}
      follow_redirect!
      #expect(last_response.body).to have_text("Working form.")
    end

end
