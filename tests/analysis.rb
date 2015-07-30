
require_relative 'base.rb'

describe "Test analysis forms" do

    before (:each) do 
      before_each() 
      login_before_each()
      upload()
    end

    after (:each) do after_each() end

    it "Do not show analysis forms for non analysts" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/cncflora_test/specie/Aphelandra+longiflora"
      follow_redirect!

      expect(last_response.body).not_to have_tag('form.analysis')
    end

    it "Do show analysis forms for analysts" do
      get "/cncflora_test/specie/Aphelandra+longiflora"
      follow_redirect!

      id1 = 'urn:occurrence:UNICAMP:UEC:10137'
      id2 = 'urn:occurrence:MBM:MBM:19751'
      id3 = 'urn:occurrence:MBM:MBM:137990'

      expect(last_response.body).to have_tag('form.analysis')
    end

    it "Edit field with analysis forms" do
      id1 = 'urn:occurrence:UNICAMP:UEC:10137'

      post "/cncflora_test/occurrences/#{id1}/analysis?q=Aphelandra+longiflora",{:remarks=>"Working form."}
      follow_redirect!
      #expect(last_response.body).to have_text("Working form.")
      #expect(last_response.body).to have_tag("textarea",:text=>"Working form.")
    end

end

