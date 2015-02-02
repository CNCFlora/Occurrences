
require_relative 'base.rb'

describe "Species listing" do

    before (:each) do before_each() ; sleep 1 end

    after (:each) do after_each() end

    it "Gets families." do
        get "/cncflora_test/families"
        expect( last_response.status ).to eq(200)
        expect( last_response.body ).to have_tag("body"){
            with_tag "a", :text=>"ACANTHACEAE"
            with_tag "a", :text=>"BALANOPHORACEAE"
            with_tag "a", :text=>"APOCYNACEAE"
        }
    end

    it "Gets a family." do
        get "/cncflora_test/family/ACANTHACEAE"
        expect( last_response.body ).to have_tag( "body" ){
            with_tag "h2", "ACANTHACEAE"
            with_tag "a", :text=>"Aphelandra longiflora" 
            without_tag "a", :text=>"Aphelandra longiflora2" 
            without_tag "a", :text=>"ACANTHACEAE" 
        }
    end

    it "Get a specie and redirect" do
        get "/cncflora_test/specie/Aphelandra%20longiflora"
        expect(last_response.status).to eq(302)
        expect(last_response.header["location"]).to include("cncflora_test")
        expect(last_response.header["location"]).to include("search")
        expect(last_response.header["location"]).to include("Aphelandra%20longiflora")
        expect(last_response.header["location"]).to include("Aphelandra%20longiflora2")
    end

end
