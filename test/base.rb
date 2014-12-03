ENV['RACK_ENV'] = 'test'

require_relative '../src/app'
require 'rspec'
require 'rack/test'
require 'rspec-html-matchers'
require 'cncflora_commons'

include Rack::Test::Methods

def app
    Sinatra::Application
end


def before_each()
    uri = "#{ Sinatra::Application.settings.couchdb }/cncflora_test"

    docs = http_get("#{uri}/_all_docs")["rows"]
    docs.each{ |e|
        deleted = http_delete( "#{uri}/#{e["id"]}?rev=#{e["value"]["rev"]}")
    }
    sleep 1

    taxons = [
        {
            "taxonID"=>"106006", 
            "family"=>"Apocynaceae", 
            "scientificName"=>"Minaria diamantinensis (Fontella) T.U.P.Konno & Rapini", 
            "scientificNameAuthorship"=>"(Fontella) T.U.P.Konno & Rapini",
            "scientificNameWithoutAuthorship"=>"Minaria diamantinensis",
            "taxonomicStatus"=>"accepted",
            "taxonRank"=>"species",
            "metadata"=> {
                "type"=> "taxon"
            }
        },
        {
            "taxonID"=>"121962",
            "family"=>"Balanophoraceae",
            "scientificName"=>"Langsdorffia heterotepala L.J.T. Cardoso, R.J.V. Alves J.M.A. Braga",
            "scientificNameAuthorship"=>"L.J.T. Cardoso, R.J.V. Alves  J.M.A. Braga",
            "scientificNameWithoutAuthorship"=>"Langsdorffia heterotepala",
            "taxonomicStatus"=>"accepted",
            "taxonRank"=>"species",
            "metadata"=> {
                "type"=> "taxon"
            }
        },
        {
            "taxonID"=> "21641",
            "family"=> "Acanthaceae",
            "scientificName"=> "Aphelandra longiflora S.Profice",
            "scientificNameAuthorship"=> "S.Profice",
            "scientificNameWithoutAuthorship"=> "Aphelandra longiflora",
            "taxonomicStatus"=> "accepted",
            "taxonRank"=> "variety",
            "metadata" => {
                "type" => "taxon"
            }
        },
        {
            "taxonID"=> "21641",
            "family"=> "Acanthaceae",
            "scientificName"=> "Aphelandra longiflora2 S.Profice",
            "scientificNameAuthorship"=> "S.Profice",
            "scientificNameWithoutAuthorship"=> "Aphelandra longiflora2",
            "taxonomicStatus"=> "synonym",
            "acceptedNameUsage"=> "Aphelandra longiflora",
            "taxonRank"=> "variety",
            "metadata" => {
                "type" => "taxon"
            }
        }
    ]

    taxons.each do |taxon|
        doc = http_post(uri,taxon)
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
    uri = "#{ Sinatra::Application.settings.couchdb }/cncflora_test"

    docs = http_get("#{uri}/_all_docs")["rows"]
    docs.each{ |e|
        deleted = http_delete( "#{uri}/#{e["id"]}?rev=#{e["value"]["rev"]}")
    }
    sleep 1
end
