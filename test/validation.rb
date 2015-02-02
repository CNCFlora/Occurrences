
require_relative 'base.rb'

describe "Test validation system" do

    before (:each) do 
      before_each() 
      post "/cncflora_test/upload", "file" => Rack::Test::UploadedFile.new("test/aphelandra_longiflora_test.xlsx"), "type"=>"xlsx"
    end

    after (:each) do after_each() end

    it "Do show validation form" do
      get "/cncflora_test/specie/Aphelandra+longiflora"
      follow_redirect!

      expect(last_response.body).to have_tag('form.validation')
    end

    it "Do not show validation form" do
      post "/login", { :user => '{"name":"Bruno", "email":"bruno@cncflora.net","roles":[] }' }

      get "/cncflora_test/specie/Aphelandra+longiflora"
      follow_redirect!

      expect(last_response.body).not_to have_tag('form.validation')
    end

    it "Gets Results of validates occurrence" do
        id1 = 'urn:occurrence:UNICAMP:UEC:10137'

        get "/cncflora_test/specie/Aphelandra%20longiflora"
        follow_redirect!

        # initial state: no occurrence validated
        expect( last_response.body ).to have_tag( "table" ){
            with_tag "#valid", :text=>0
            with_tag "#invalid", :text=>0
            with_tag "#validated", :text=>0
            with_tag "#not_validated", :text=>3
            with_tag "#total", :text=>3
        }

        # The query by scientificName
        validation = {
            "q"=>"Aphelandra%20longiflora",
            "taxonomy"=>"valid", 
            "georeference"=>"valid"
        }

        post "/cncflora_test/occurrences/#{id1}/validate", validation
        follow_redirect!

        # after first validation: 1 occ valid
        expect( last_response.body ).to have_tag( "table" ){
            with_tag "#valid", :text=>1
            with_tag "#invalid", :text=>0
            with_tag "#validated", :text=>1
            with_tag "#not_validated", :text=>2
            with_tag "#total", :text=>3
        }

        # second validation: invalid
        validation = {
            "q"=>"Aphelandra%20longiflora",
            "taxonomy"=>"invalid", 
            "georeference"=>"valid"
        }

        post "/cncflora_test/occurrences/#{id1}/validate", validation
        follow_redirect!

        # after second validation: 1 invalid
        expect( last_response.body ).to have_tag( "table" ){
            with_tag "#valid", :text=>0
            with_tag "#invalid", :text=>1
            with_tag "#validated", :text=>1
            with_tag "#not_validated", :text=>2
            with_tag "#total", :text=>3
        }
    end

end

