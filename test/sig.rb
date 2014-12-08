
require_relative 'base.rb'

describe "Test GIS forms" do

    before (:each) do 
      before_each() 
      post "/cncflora_test/upload", "file" => Rack::Test::UploadedFile.new("test/aphelandra_longiflora_test.xlsx"), "type"=>"xlsx"
      sleep 1
    end

    after (:each) do after_each() end

    it "Do not show sig forms for non analysts" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/cncflora_test/specie/Aphelandra+longiflora"
      follow_redirect!

      expect(last_response.body).not_to have_tag('form.gis')
    end

    it "Do show gis forms for analysts" do
      get "/cncflora_test/specie/Aphelandra+longiflora"
      follow_redirect!

      id1 = 'urn:occurrence:UNICAMP:UEC:10137'
      id2 = 'urn:occurrence:MBM:MBM:19751'
      id3 = 'urn:occurrence:MBM:MBM:137990'

      expect(last_response.body).to have_tag('form.sig')
    end

    it "Edit field with analysis forms" do
      id1 = 'urn:occurrence:UNICAMP:UEC:10137'

      post "/cncflora_test/occurrences/#{id1}/sig?q=Aphelandra+longiflora",{:comment=>"Working form."}
      sleep 2
      follow_redirect!
      #expect(last_response.body).to have_text("Working form.")
    end

end
