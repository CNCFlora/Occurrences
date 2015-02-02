
require_relative 'base.rb'

describe "Spreadsheet and csv upload" do

    before (:each) do before_each() end

    after (:each) do after_each() end

    it "Gets occurrences upload sending page." do
        get "/cncflora_test/upload"
        expect( last_response.status ).to eq( 200 )
        expect( last_response.body ).to have_form("/cncflora_test/upload", :POST ) do
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
        post "/cncflora_test/upload", "file" => Rack::Test::UploadedFile.new("test/aphelandra_longiflora_test.xlsx"), "type"=>"xlsx"

        expect(last_response.body).to have_tag("h2",:text=>"Registros de ocorrências inseridos: 3.")
        expect(last_response.body).to have_tag("a",:text=>"Aphelandra longiflora")

        get "/cncflora_test/specie/Aphelandra%20longiflora"
        follow_redirect!
        expect(last_response.body).to have_tag("td#total",:text=>"3")
    end

end

