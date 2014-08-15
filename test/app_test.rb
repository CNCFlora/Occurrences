ENV['RACK_ENV'] = 'test'

require_relative '../src/app'
require 'rspec'
require 'rack/test'
require 'rspec-html-matchers'
require 'cncflora_commons'
require 'i18n'

include Rack::Test::Methods

def app
    Sinatra::Application
end

describe "Web app Occurrence." do

    before(:each) do
        @uri =  Sinatra::Application.settings.couchdb

        @taxons = [
            {
                "taxonID"=>"106006", "family"=>"Apocynaceae", "genus"=>"Minaria",
                "scientificName"=>"Minaria diamantinensis (Fontella) T.U.P.Konno & Rapini", "scientificNameAuthorship"=>"(Fontella) T.U.P.Konno & Rapini",
                "scientificNameWithoutAuthorship"=>"Minaria diamantinensis", "taxonomicStatus"=>"accepted",
                "acceptedNameUsage"=>"Minaria diamantinensis (Fontella) T.U.P.Konno & Rapini", "taxonRank"=>"species",
                "higherClassification"=>"Flora;Angiospermas;Apocynaceae;Minaria T.U.P.Konno & Rapini;Minaria diamantinensis (Fontella) T.U.P.Konno & Rapini",
                "metadata"=> {
                    "type"=> "taxon"
                }
            },


            {
                     
                "taxonID"=>"121962", "family"=>"Balanophoraceae",
                "genus"=>"Langsdorffia", "scientificName"=>"Langsdorffia heterotepala L.J.T. Cardoso, R.J.V. Alves J.M.A. Braga",
                "scientificNameAuthorship"=>"L.J.T. Cardoso, R.J.V. Alves  J.M.A. Braga",
                "scientificNameWithoutAuthorship"=>"Langsdorffia heterotepala L.J.T. Cardoso, R.J.V. Alves J.M.A. Braga", "taxonomicStatus"=>"accepted",
                "acceptedNameUsage"=>"Langsdorffia heterotepala L.J.T. Cardoso, R.J.V. Alves J.M.A. Braga", "taxonRank"=>"species",
                "higherClassification"=>"Flora;Angiospermas;Balanophoraceae Rich.;Langsdorffia Mart.;Langsdorffia heterotepala L.J.T. Cardoso, R.J.V. Alves J.M.A. Braga",
                "metadata"=> {
                    "type"=> "taxon"
                }
            },


            {
                "taxonID"=> "21641","family"=> "Acanthaceae","genus"=> "Aphelandra",
                "scientificName"=> "Aphelandra aurantiaca (Scheidw.) Lindl. var. aurantiaca","scientificNameAuthorship"=> "(Scheidw.) Lindl.",
                "scientificNameWithoutAuthorship"=> "Aphelandra aurantiaca  var. aurantiaca","taxonomicStatus"=> "accepted",
                "acceptedNameUsage"=> "Aphelandra aurantiaca (Scheidw.) Lindl. var. aurantiaca","taxonRank"=> "variety",
                "higherClassification"=> "Flora;Angiospermas;Acanthaceae Juss.;Aphelandra R.Br.;Aphelandra aurantiaca (Scheidw.) Lindl.;Aphelandra aurantiaca (Scheidw.) Lindl. var. aurantiaca",
                "metadata" => {
                    "type" => "taxon"
                }
            }

        ]

        @ids = []

        @taxons.each do |taxon|
            doc = http_post( @uri,taxon)
            @ids << { "id"=>doc["id"], "rev"=>doc["rev"] }
        end
        sleep 1

    end


    after(:each) do
        @ids.each do |e|
            http_delete( "#{@uri}/#{e["id"]}?rev=#{e["rev"]}")
        end
        sleep 2
    end


    before(:each) do
        user = {
            :user => '{"name":"Bruno",' \
                '"email":"bruno@cncflora.net",' \
                '"roles":[' \
                    '{"role":"assessor","entities":["ACANTHACEAE","BALANOPHORACEAE","APOCYNACEAE"]},' \
                    '{"role":"sig","entities":["ACANTHACEAE","BALANOPHORACEAE","APOCYNACEAE"]}' \
                ']' \
            '}'
        }


        post "/login", user
    end


    it "Gets login page." do
        #It's necessary make logout because there is "post '/login' at before(:each)."
        post "/logout"
        expect( last_response.status ).to eq( 204 )
        get "/"
        expect( last_response.body ).to have_tag( "nav.navbar.navbar-default.col-md-12" ){
            expect( last_response.body ).to have_tag( "ul.nav.navbar-nav" ){
                with_tag "li#login a", :with=>{ href: "#"}, :text=>"Login"
                without_tag "li a", :with=>{ href: "/"}, :text=>"Resumo"
                without_tag "li a", :with=>{ href: "/families"}, :text=>"Familias"
                without_tag "li a", :with=>{ href: "/upload"}, :text=>"Enviar ocorrências"
                without_tag "li a", :with=>{ href: "#"}, :text=>"Logout"
            }
        }
        expect( last_response.body ).to have_tag( "h2.col-md-12", "Necessário fazer login" )

    end


    it "Goes to home page after login." do
        get "/"
        expect( last_response.status ).to eq( 200 )
        expect( last_response.body ).to have_tag( "nav.navbar.navbar-default.col-md-12" ){
            expect( last_response.body ).to have_tag( "ul.nav.navbar-nav" ){
                with_tag "li a", :with=>{ href: "/"}, :text=>"Resumo"
                with_tag "li a", :with=>{ href: "/families"}, :text=>"Famílias"
                with_tag "li a", :with=>{ href: "/upload"}, :text=>"Enviar ocorrências"
                with_tag "li#logout a", :with=>{ href: "#"}, :text=>"Logout"
                without_tag "li#id a", :with=>{ href: "#"}, :text=>"Login"
            }
            expect( last_response.body ).to have_tag( "div.col-md-12"){
                expect( last_response.body ).to have_tag( "table.table" ){
                    with_tag "tr th", :text=>"Família"
                    with_tag "tr th", :text=>"Revisado"
                    with_tag "tr th", :text=>"Validado"
                    with_tag "tr th", :text=>"Não revisado"
                    with_tag "tr th", :text=>"Não validado"
                    with_tag "tr th", :text=>"Total"
                }
            }
        }

    end


    it "Gets families." do
        get "/families"
        expect( last_response.status ).to eq( 200 )
        expect( last_response.body ).to have_tag( "div.col-md-12"){
            with_tag "h2","Famílias"
            @taxons.each do |taxon|
                puts "family: #{taxon["family"]}"
                #with_tag "ul li a", :with=>{ href: "/family/#{taxon["family"]}" }, :text=>"#{taxon["family"]}"
                with_tag "ul li a", :with=>{ href: "/family/#{taxon["family"]}" }
            end
        }
    end


    it "Gets a family." do
        taxon = @taxons.last
        get "/family/#{taxon["family"]}"
        sleep 2
        expect( last_response.status ).to eq( 200 )
        expect( last_response.body ).to have_tag( "div.col-md-12" ){
            with_tag "h2", "#{taxon["family"]}"
            expect( last_response.body ).to have_tag( "table.table" ){
                with_tag "thead tr th", :text=>"Espécie"
                @taxons.each{ |taxon|
                    puts "taxon: #{taxon["scientificNameWithoutAuthorship"]}"
                    #with_tag "tbody tr td i a", :with=>{ href: "/specie/#{taxon["scientificNameWithoutAuthorship"]}" }
                }
                # Missing td :text ' (Scheidw.) Lindl.'
                #with_tag "tbody tr td i a", :with=>{ href: "/specie/#{@taxons.last["scientificNameWithoutAuthorship"]}" }, :text=>" #{scientificName}"??
            }
        }
    end


    it "Gets specie by name with sig profile." do
        taxon = @taxons.last["scientificNameWithoutAuthorship"]
        get "/specie/#{URI.encode( taxon )}"
        expect( last_response.status ).to eq( 302 )
        follow_redirect!
        expect( last_response.body ).to have_tag( "h2", :text => "Busca" )
        expect( last_response.body ).to have_tag( "form", :with => { :action => '/search' } ){
            expect( last_response.body ).to have_tag( "fieldset" ){
                with_tag "p#input-taxon-search input.form-control", :with => { :name=>"q", :type=>"text", :value=>"\"#{taxon}\"", :placeholder=>"Busca..." }
                with_tag "p#button-taxon-search button.btn.btn-primary", :text=>" Busca"
                with_tag "p#button-taxon-search button.btn.btn-primary span.glyphicon.glyphicon-search"
                with_tag "p#button-taxon-search a.btn.btn-default.btn-small",  :with=> { href: "/editor?q=\"#{taxon}\"" }
            }
        }
    end


    it "Gets specie by name without sig profile." do
        taxon = @taxons.last["scientificNameWithoutAuthorship"]
        post '/logout'
        post '/login', :user => '{ "name":"foo","email":"foo@cncflora.net", "roles":[ {"role":"assessor","entities":["ACANTHACEAE"]} ] }'
        get "/specie/#{URI.encode( taxon )}"
        expect( last_response.status ).to eq( 302 )
        follow_redirect!
        expect( last_response.body ).to have_tag( "h2", :text => "Busca" )
        expect( last_response.body ).to have_tag( "form", :with => { :action => '/search' } ) do
            expect( last_response.body ).to have_tag( :p ) do
                with_tag "input.form-control", :with => { :name=>"q", :type=>"text", :value=>"\"#{taxon}\"", :placeholder=>"Busca..." }
                expect( last_response.body ).to have_tag( "button.btn.btn-primary", :text=>" Busca" ) do
                    with_tag "span.glyphicon.glyphicon-search"
                end
                expect( last_response.body ).not_to have_tag( "a.btn.btn-default.btn-small",  with: { href: "/editor?q=\"#{taxon}\"" } )
            end
        end
    end


    it "Gets specie by name and status." do
        pending( "Not yet implemented. This route calls a service" )
        this_should_not_get_executed
    end


    it "Gets occurrences upload sending page." do
        get "/upload"
        expect( last_response.status ).to eq( 200 )
        expect( last_response.body ).to have_form("/upload", :POST, with: { class: "col-md-12" } ) do
            with_tag :legend, :text => "Enviar arquivo:"
            expect( last_response.body ).to have_tag( "div.form-group.input-group.col-md-6") do
                with_tag( "input.form-control", :with => { :id=>"file", :name=>"file", :type=>"file"  } )
                expect( last_response.body ).to have_tag( "span.input-group-addon") do
                    with_select( "type", :with => { :id=>"type"} )
                    with_option( "XLSX", :value => "xlsx")
                    with_option( "CSV", :value => "csv")
                    with_option( "DWC-A", :value => "dwca" )                 
                end
                expect( last_response.body ).to have_tag( "span.input-group-btn"){
                    with_button( "Enviar", :class=>"btn btn-success")
                }
                expect( last_response.body ).to have_tag( "p" ){
                    with_tag "strong", "Templates/Modelos"
                    with_tag "a", :wiht => { :href=>"templates/occurrences.xlsx", :text=>"occurrences.xlsx" }
                }
            end
        end
    end


    it "Does upload xlsx file" do
        post "/upload", "file" => Rack::Test::UploadedFile.new("test/aphelandra_aurantiaca_test1.xlsx"), "type"=>"xlsx"
        

        docs = http_get( "#{@uri}/_all_docs?include_docs=true" )

        occurrences = []
        docs["rows"].each{ |row|
            if ( row["doc"]["metadata"]["type"] == "occurrence" )

                occurrences.push( {"id"=>row["doc"]["_id"], "rev"=>row["doc"]["_rev"], "scientificName"=>row["doc"]["scientificName"] } )
            end
        }


        expect( last_response.body ).to have_tag( "div.col-md-12" ){
            with_tag( "h2", :text=>"Registros de ocorrências Inseridos: #{occurrences.count}." )
            occurrences.each{ |occurrence|
                expect( last_response.body ).to have_tag( "ul li a", :with=>{ :href=>"/search?q=\"#{occurrence["scientificName"]}\"" }, :text=>occurrence["scientificName"] )
            }
        }


        # Delete all registers included on post action above.
        occurrences.each{ |occurrence|
            result = http_delete( "#{@uri}/#{occurrence["id"]}?rev=#{occurrence["rev"]}" )
        }
    end
end
