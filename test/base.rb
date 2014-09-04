ENV['RACK_ENV'] = 'test'

require 'sinatra/advanced_routes'
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

@uri = Sinatra::Application.settings.couchdb
@taxons = []

def before_each()
    @uri =  Sinatra::Application.settings.couchdb

    @taxons = [
        {
            "taxonID"=>"106006", 
            "family"=>"Apocynaceae", 
            "genus"=>"Minaria",
            "scientificName"=>"Minaria diamantinensis (Fontella) T.U.P.Konno & Rapini", 
            "scientificNameAuthorship"=>"(Fontella) T.U.P.Konno & Rapini",
            "scientificNameWithoutAuthorship"=>"Minaria diamantinensis",
            "taxonomicStatus"=>"accepted",
            "acceptedNameUsage"=>"Minaria diamantinensis (Fontella) T.U.P.Konno & Rapini", 
            "taxonRank"=>"species",
            "metadata"=> {
                "type"=> "taxon"
            }
        },
        {
            "taxonID"=>"121962",
            "family"=>"Balanophoraceae",
            "genus"=>"Langsdorffia",
            "scientificName"=>"Langsdorffia heterotepala L.J.T. Cardoso, R.J.V. Alves J.M.A. Braga",
            "scientificNameAuthorship"=>"L.J.T. Cardoso, R.J.V. Alves  J.M.A. Braga",
            "scientificNameWithoutAuthorship"=>"Langsdorffia heterotepala",
            "taxonomicStatus"=>"accepted",
            "acceptedNameUsage"=>"Langsdorffia heterotepala L.J.T. Cardoso, R.J.V. Alves J.M.A. Braga",
            "taxonRank"=>"species",
            "metadata"=> {
                "type"=> "taxon"
            }
        },
        {
            "taxonID"=> "21641",
            "family"=> "Acanthaceae",
            "genus"=> "Aphelandra",
            "scientificName"=> "Aphelandra aurantiaca (Scheidw.) Lindl. var. aurantiaca",
            "scientificNameAuthorship"=> "(Scheidw.) Lindl.",
            "scientificNameWithoutAuthorship"=> "Aphelandra aurantiaca  var. aurantiaca",
            "taxonomicStatus"=> "accepted",
            "acceptedNameUsage"=> "Aphelandra aurantiaca (Scheidw.) Lindl. var. aurantiaca",
            "taxonRank"=> "variety",
            "metadata" => {
                "type" => "taxon"
            }
        }
    ]

    @taxons.each do |taxon|
        doc = http_post(@uri,taxon)
    end

    post "/login", {
        :user => '{"name":"Bruno",' \
            '"email":"bruno@cncflora.net",' \
            '"roles":[' \
                '{"role":"assessor","entities":["ACANTHACEAE","BALANOPHORACEAE","APOCYNACEAE"]},' \
                '{"role":"validator","entities":["ACANTHACEAE","BALANOPHORACEAE","APOCYNACEAE"]},' \
                '{"role":"sig","entities":["ACANTHACEAE","BALANOPHORACEAE","APOCYNACEAE"]}' \
            ']' \
        '}'
    }

    sleep 1
end

def after_each()
    docs = http_get("#{@uri}/_all_docs")["rows"]
    docs.each{ |e|
        deleted = http_delete( "#{@uri}/#{e["id"]}?rev=#{e["value"]["rev"]}")
    }
    sleep 1
end
