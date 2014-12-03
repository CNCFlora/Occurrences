
require_relative 'base.rb'

describe "Spreadsheet and csv upload" do

    before (:each) do before_each() end

    after (:each) do after_each() end

    it "Gets occurrences upload sending page." do
        get "/upload"
        expect( last_response.status ).to eq( 200 )
        expect( last_response.body ).to have_form("/upload", :POST ) do
            with_tag :legend, :text => "Enviar arquivo:"
            with_tag( "input", :with => { :id=>"file", :name=>"file", :type=>"file"} )
            with_select( "type", :with => { :id=>"type"} )
            with_option( "XLSX", :value => "xlsx")
            with_option( "CSV", :value => "csv")
            with_option( "DWC-A", :value => "dwca" )                 
            with_button( "Enviar")
        end
    end

    it "Does upload xlsx file" do
        post "/upload", "file" => Rack::Test::UploadedFile.new("test/aphelandra_aurantiaca_test.xlsx"), "type"=>"xlsx"

        sleep 1

        docs = http_get( "#{@uri}/_all_docs?include_docs=true" )

        occurrences = []
        docs["rows"].each{ |row|
            if ( row["doc"]["metadata"]["type"] == "occurrence" )
                occurrences.push( row["doc"] )
            end
        }

        expect( last_response.body ).to have_tag( "body" ){
            with_tag( "h2", :text=>"Registros de ocorrências Inseridos: #{occurrences.count}." )
            occurrences.each{ |occurrence|
                expect( last_response.body ).to have_tag( "a", :with=>{ :href=>"/search?q=\"#{occurrence["scientificName"]}\"" }, :text=>occurrence["scientificName"] )
            }
        }

        get "/search?q=#{URI.encode(occurrences[0]["scientificName"])}"
        expect(last_response.body).to have_tag("td#total",:text=>"3")
        expect(last_response.body).to have_tag("a",:with=>{:name=>"occ-#{occurrences[0]["_id"]}-unit"})

    end

end

