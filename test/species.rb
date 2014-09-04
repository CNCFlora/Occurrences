
require_relative 'base.rb'

describe "Test web login" do

    before (:each) do before_each() end

    after (:each) do after_each() end

    it "Gets families." do
        get "/families"
        expect( last_response.status ).to eq(200)
        expect( last_response.body ).to have_tag("body"){
            with_tag "h2","Famílias"
            @taxons.each do |taxon|
                with_tag "a", :with=>{ href: "/family/#{taxon["family"].upcase}" }, :text=>"#{taxon["family"].upcase}"
            end
        }
    end

    it "Gets a family." do
        taxon = @taxons.last
        get "/family/#{taxon["family"]}"
        expect( last_response.status ).to eq( 200 )
        expect( last_response.body ).to have_tag( "body" ){
            with_tag "h2", "#{taxon["family"]}"
            with_tag "a", :with=>{ href: "/specie/#{taxon["scientificNameWithoutAuthorship"]}" }
        }
    end

    it "Get a specie and redirect" do
        taxon = @taxons.last
        get "/specie/#{taxon["scientificNameWithoutAuthorship"].gsub(" ","%20")}"
        expect( last_response.status ).to eq(302)
        expect(last_response.header[ "location" ]).to start_with("http://example.org/search")
    end

end
