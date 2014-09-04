
require_relative 'base.rb'

describe "Test web login" do

    before (:each) do 
        before_each() 
        post "/upload", "file" => Rack::Test::UploadedFile.new("test/aphelandra_aurantiaca_test.xlsx"), "type"=>"xlsx"
        sleep 1
    end

    after (:each) do after_each() end

    it "Gets validation form of occurrence page after uploading file." do
        # Search occurrences inserted.
        result = http_get( "#{@uri}/_all_docs?include_docs=true")["rows"]
        occurrence = result.find { |e| e["doc"]["metadata"]["type"] == "occurrence"}["doc"]

        # Clicks on the specie link.
        get "/specie/#{URI.encode(occurrence["scientificName"])}"
        follow_redirect!

        expect( last_response.body ).to have_tag( "form", :with=>{:action=>"/occurrences/#{occurrence["_id"]}/validate"} )
    end

    it "Gets Results of validates occurrence" do
        result = http_get( "#{@uri}/_all_docs?include_docs=true")["rows"]
        occurrence = result.find { |e| e["doc"]["metadata"]["type"] == "occurrence"}["doc"]

        get "/specie/#{URI.encode(occurrence["scientificName"])}"
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
            "q"=>occurrence["scientificName"],
            "taxonomy"=>"valid", 
            "georeference"=>"valid"
        }

        post "/occurrences/#{occurrence["_id"]}/validate", validation
        sleep 1
        expect( last_response.status ).to eq(302)
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
            "q"=>occurrence["scientificName"],
            "taxonomy"=>"invalid", 
            "georeference"=>"valid"
        }

        post "/occurrences/#{occurrence["_id"]}/validate", validation
        sleep 1
        expect( last_response.status ).to eq(302)
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

