
require_relative 'base.rb'

describe "Simple search?" do

    before (:each) do before_each() end

    after (:each) do after_each() end

    it "Gets specie by name with sig profile." do
        taxon = @taxons.last["scientificNameWithoutAuthorship"]
        get "/specie/#{URI.encode( taxon )}"
        expect( last_response.status ).to eq( 302 )
        follow_redirect!
        expect( last_response.body ).to have_tag( "h2", "Busca" )
        expect( last_response.body ).to have_tag( "form"){
            with_tag "input[name=q]", :with => { :name=>"q", :value=>"\"#{taxon}\""}
            with_tag "a",  :with=> { href: "/editor?q=\"#{taxon}\"" }
        }
    end

    it "Gets specie by name without sig profile." do
        taxon = @taxons.last["scientificNameWithoutAuthorship"]
        post '/logout'
        post '/login', :user => '{ "name":"foo","email":"foo@cncflora.net", "roles":[ {"role":"assessor","entities":["ACANTHACEAE"]} ] }'
        get "/specie/#{URI.encode( taxon )}"
        follow_redirect!
        expect( last_response.body ).to have_tag( "h2", "Busca" )
        expect( last_response.body ).to have_tag( "form"){
            with_tag "input[name=q]", :with => { :name=>"q", :value=>"\"#{taxon}\""}
            without_tag "a",  :with=> { href: "/editor?q=\"#{taxon}\"" }
        }
    end

end
