Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development?

require 'rest-client'

require 'securerandom'
require 'json'
require 'uri'

config_file ENV['config'] || 'config.yml'
use Rack::Session::Pool
set :session_secret, '1flora2'

config = {}

if settings.etcd
    etcd = JSON.parse(RestClient.get("#{settings.etcd}/v2/keys/?recursive=true")) 
    etcd['node']['nodes'].each {|node|
        if node.has_key?('nodes')
            node['nodes'].each {|entry|
                if entry.has_key?('value') && entry['value'].length >= 1 
                    key = entry['key'].gsub("/","_").downcase()[1..-1]
                    config[key.to_sym] = entry['value']
                end
            }
        end
    }
end

config[:connect] = "http://#{config[:connect_host ]}:#{config[:connect_port]}"
config[:strings] = JSON.parse(File.read("locales/#{settings.lang}.json", :encoding => "BINARY"))
config[:services] = "http://192.168.50.30:3000/api/v1"
config[:self] = settings.self
config[:base] = settings.base

set :config, config

def view(page,data)
    @config = settings.config
    @session_hash = {:logged => session[:logged] || false, :user => session[:user] || '{}'}
    if session[:logged] 
        session[:user]['roles'].each do | role |
            @session_hash["role-#{role['role'].downcase}"] = true
        end
    end
    @session_hash["role-analyst"]=true
    @session_hash["role-sig"]=true
    @session_hash["role-validator"]=true
    mustache page, {}, @config.merge(@session_hash).merge(data)
end

post '/login' do
    session[:logged] = true
    session[:user] = JSON.parse(params[:user])
    204
end

post '/logout' do
    session[:logged] = false
    session[:user] = false
    204
end

get '/' do
    species = []
    if session[:logged]
        user_taxons = []
        session[:user]["roles"].each {|r|
            r["entities"].each {|e|
                user_families.push(e["name"])
            }
        }
        # TODO: list according to user profile
        species.push( {:family=>'ACANTHACEAE',:scientificName=>'Aphelandra longiflora', :total=>20,:reviewed=>10,:validated=>5})
    end
    view :index,{:species=>species}
end

get '/upload' do
    view :upload,{}
end

post '/upload' do
    errors = []
    file = "./public/uploads/#{SecureRandom.uuid()}"
    json = ""

    begin
        if params.has_key?("file") 
            # convert to json
            json = RestClient.post "#{config[:services]}/convert?from=#{params["type"]}&to=json", 
                                params["file"][:tempfile].read, :content_type => params["file"][:type], :accept => :json

            if json[0] != '[' # cause it must be an array back
                errors.push json
            else
                # validate
                validation = RestClient.post "#{config[:services]}/validate", json,
                                    :content_type => params["file"][:type], :accept => :json
                validation = JSON.parse(validation.to_str)

                if validation.length > 0
                    validation.each{ |v|
                        v.each { |vv|
                            errors.push("#{vv['error']} #{vv['data']} #{vv['ref']}")
                        }
                    }
                else
                    # also convert to geojson, to integrate with the editor
                    geojson = RestClient.post "#{config[:services]}/convert?from=json&to=geojson", json,
                                                :content_type => params["file"][:type], :accept => :json
                    File.open("#{file}.json",'w') { |f| f.write(json) }
                    File.open("#{file}.geojson",'w') { |f| f.write(geojson) }
                end
            end
        else
            errors.push("Must upload a file!")
        end
    rescue Exception => e
        puts "Exception!"
        errors.push e.message
        puts e.message  
        puts e.backtrace.inspect  
    end

    has_errors = errors.length > 0

    if has_errors 
        view :upload, {:errors=>errors,:has_errors=>has_errors}
    else
        redirect "/insert?data=#{URI.encode(json)}"
    end
end

get '/insert' do
    data = JSON.parse(params[:data])

    # TODO: insert into couchdb

    count = data.length
    species = []
    data.each {|occ|
        puts occ
        species.push occ["scientificName"]
    }
    view :inserted, {:count=>count,:species=>species}
end

post '/insert' do
    data = JSON.parse(request.body.read.to_s)

    # TODO: insert into couchdb

    count = data.length
    species = []
    data.each {|occ|
        puts occ
        species.push occ["scientificName"]
    }
    view :inserted, {:count=>count,:species=>species}
end

get '/families' do
    families=[]
    # TODO: search families
    view :families, {:families=>families}
end

get '/family/:family' do
    family = params[:family]
    species= []
    # TODO: search species of family
    view :family, {:species=>species,:family=>family}
end

get '/search' do
    occurrences = []
    query = params[:q]

    # TODO: perform serach
    
    occurrences.push({
        :occurrenceID=> "123",
        :decimalLatitude=> -40.10,
        :decimalLongitude=> -20.20,
        :valid=> false
    })

    occurrences.each{|occ| occ[:json] = JSON.dump(occ) }

    view :search, {:result=>occurrences,:query=>query}
end

post '/occurrences/:id/sig' do
    redirect "/search?q=#{URI.encode( params[:q] )}"
end

post '/occurrences/:id/analysis' do
    redirect "/search?q=#{URI.encode( params[:q] )}"
end

post '/occurrences/:id/validate' do
    redirect "/search?q=#{URI.encode(params[:q])}"
end

