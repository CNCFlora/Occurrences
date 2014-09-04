require_relative 'base.rb'

describe "Test web login" do

    before (:each) do before_each() end

    after (:each) do after_each() end

    it "Gets login page." do
        #It's necessary make logout because there is "post '/login' at before(:each)."
        post "/logout"
        expect( last_response.status ).to eq( 204 )
        get "/"
        expect(last_response.body).to have_tag("body") do
            with_tag "#login" 
            without_tag "#logout"  
        end
        expect(last_response.body).to have_tag("h2", "Necessário fazer login" )  

    end

    it "Gets routes without logon" do
        #It's necessary make logout because there is "post '/login' at before(:each)."
        post "/logout"

        taxon = http_get( "#{@uri}/_all_docs?include_docs=true" )["rows"].first["doc"]
        routes_keys = { "id"=>taxon["_id"],"family"=>taxon["family"].upcase,"name"=>taxon["scientificNameWithoutAuthorship"] }
        routes_no_test = ["/", "/login", "/logout", "/specie/:name/:status"]
        #verb_no_test = ["HEAD","POST"]

        Sinatra::Application.each_route {|element|
            if !routes_no_test.include? element.path
                element.keys.each {|k|
                    element.path[":#{k}"] = URI.encode(routes_keys[k]) unless element.path[":#{k}"].nil?
                }

                if element.verb == "GET"
                    get element.path
                    expect( last_response.status ).to eq(302)
                    expect( last_response.header['location'] ).to eq("http://example.org/")
                end
            end
        }
    end


    it "Goes to home page after login." do
        get "/"
        expect( last_response.status ).to eq( 200 )
        expect( last_response.body ).to have_tag( "body" ){
            with_tag "li#logout a", :with=>{ href: "#"}, :text=>"Logout"
            without_tag "li#id a", :with=>{ href: "#"}, :text=>"Login"
        }
    end

end
