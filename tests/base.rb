ENV['RACK_ENV'] = 'test'

require_relative '../src/app'
require 'rspec'
require 'rack/test'
require 'rspec-html-matchers'

include Rack::Test::Methods

def app
    Sinatra::Application
end

RSpec.configure do |config|
  config.include RSpecHtmlMatchers
end


def before_each()
    uri = "#{ Sinatra::Application.settings.couchdb }/cncflora_test"
    uri2 = "#{ Sinatra::Application.settings.elasticsearch }/cncflora_test"

    docs = http_get("#{uri}/_all_docs?include_docs=true")["rows"]
    docs.each{ |e|
        deleted = http_delete("#{uri}/#{e["id"]}?rev=#{e["value"]["rev"]}")
        r=http_delete("#{uri2}/#{e["doc"]["metadata"]["type"]}/#{e["id"]}")
    }

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
        taxon["_id"] = doc["id"]
        taxon["_rev"] = doc["rev"]
        es_index("cncflora_test",taxon)
    end

    roles = [{:context=>"cncflora_test",:roles=>[{:role=>'analyst',:entities=>["ACANTHACEAE"]},{:role=>"sig",:entities=>["ACANTHACEAE"]},{:role=>"validator",:entities=>["ACANTHACEAE"]}]}].to_json
    post "/login", { :user => "{\"name\":\"Diogo\", \"email\":\"diogo@cncflora.net\",\"roles\":#{roles}}"}

end

def after_each()
    uri = "#{ Sinatra::Application.settings.couchdb }/cncflora_test"
    uri2 = "#{ Sinatra::Application.settings.elasticsearch }/cncflora_test"

    docs = http_get("#{uri}/_all_docs?include_docs=true")["rows"]
    docs.each{ |e|
        deleted = http_delete("#{uri}/#{e["id"]}?rev=#{e["value"]["rev"]}")
        r=http_delete("#{uri2}/#{e["doc"]["metadata"]["type"]}/#{e["id"]}")
    }
end

def upload()
    post "/cncflora_test/upload", "file" => Rack::Test::UploadedFile.new("tests/aphelandra_longiflora_test.xlsx"), "type"=>"xlsx"
end
