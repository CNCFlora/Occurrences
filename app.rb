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
require 'net/http'

require_relative 'setup'

if development?
    also_reload "setup.rb"
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
    species = {}
    if session[:logged]
        session[:user]["roles"].each {|r|
            r["entities"].each {|e|
                species[e["name"]] = {
                    :scientificName=>e["name"],
                    :reviewed=>0,
                    :validated=>0,
                    :valid=>0,
                    :invalid=>0,
                    :total=>0
                }
            }
        }

        query = "\"#{species.keys.join("\" OR \"")}\""
        search("cncflora2",query).each {|occ|
            taxon = species[occ["scientificName"]]
            if taxon 
                taxon.total += 1;

                if occ.has_key?("georeferenceVerificationStatus") 
                    taxon.reviewed += 1;
                end

                if occ.has_key?("validation")
                    if occ["validation"].has_key?("status")
                        if occ["validation"]["status"] === 'valid'
                            taxon.validated += 1
                            taxon.valid += 1
                        elsif occ["validation"]["status"] === 'invalid'
                            taxon.validated += 1
                            taxon.invalid += 1
                        end
                    end
                end
            end
        }
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
            json = RestClient.post "#{settings.config[:services]}/convert?from=#{params["type"]}&to=json&fixes=true", 
                                params["file"][:tempfile].read, :content_type => params["file"][:type], :accept => :json

            if json[0] != '[' # cause it must be an array back
                errors.push json
            else
                # validate
                validation = RestClient.post "#{settings.config[:services]}/validate", json,
                                    :content_type => params["file"][:type], :accept => :json

                validation = JSON.parse(validation)

                if validation.class == Array
                    validation.each{ |v|
                        if v.class == Array
                            v.each { |vv|
                                errors.push("#{vv['path']} #{vv['error']} #{vv['data']} #{vv['ref']}"
                                            .gsub("=>"," ").gsub("["," ").gsub("]"," ").gsub("\"","").gsub("-"," ")
                                            .gsub("}"," ").gsub("{"," "))
                            }
                        end
                    }
                else
                    # also convert to geojson, to integrate with the editor
                    geojson = RestClient.post "#{settings.config[:services]}/convert?from=json&to=geojson", json,
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
        redirect "#{settings.config[:base]}/insert?data=#{URI.encode(json)}"
    end
end

get '/insert' do
    data = JSON.parse(params[:data])
    count = data.length
    species = []

    data.each {|occ|
        species.push occ["scientificName"]
        occ[:_id] = occ["occurrenceID"]
        occ[:metadata] = {
            # TODO: fill in
            :type => "occurrence"
        }
    }

    http_post("#{settings.config[:datahub]}/cncflora2/_bulk_docs",{"docs"=> data});

    view :inserted, {:count=>count,:species=>species.uniq}
end

post '/insert' do
    data = JSON.parse(request.body.read.to_s)
    count = data.length
    species = []

    data.each {|occ|
        species.push occ["scientificName"]
        occ["_id"] = occ["occurrenceID"]
        occ[:metadata] = {
            # TODO: fill in
            :type => "occurrence"
        }
    }

    http_post("#{settings.config[:datahub]}/cncflora2/_bulk_docs",{"docs"=> data});

    view :inserted, {:count=>count,:species=>species.uniq}
end

get '/families' do
    families=[]

    r = search("cncflora2","taxonRank:'family'")
    r.each{|taxon|
        families.push taxon["family"]
    }

    view :families, {:families=>families.uniq.sort}
end

get '/family/:family' do
    family = params[:family]
    species= search("cncflora2","family:\"#{family}\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")
                    .sort {|t1,t2| t1["scientificName"] <=> t2["scientificName"] }
    view :family, {:species=>species,:family=>family}
end

get '/search' do
    query = params[:q]
    occurrences = search("cncflora2",query)

    valid=0
    invalid=0
    reviewed=0
    validated=0
    eoo="soon"
    aoo="soon"
    i=0
    occurrences.each{ |occ| 
        occ[:json] = JSON.dump(occ) 
        occ[:occurrenceID2] = i

        if occ.has_key?("georeferenceVerificationStatus") 
            reviewed += 1;
        end

        if occ.has_key?("validation")
            if occ["validation"].has_key?("status")
                if occ["validation"]["status"] === 'valid'
                    validated += 1
                    valid += 1
                    occ["valid"] = true
                    occ["invalid"] = false 
                elsif occ["validation"]["status"] === 'invalid'
                    validated += 1
                    invalid += 1
                    occ["valid"] = false
                    occ["invalid"] = true
                end
            end
            if occ["validation"].has_key?("reason")
                occ["reason-#{occ["validation"]["reason"].gsub(" ","-")}".to_sym] = true
            end
            if occ.has_key?("occurrenceStatus")
                occ["presence-#{occ["occurrenceStatus"]}".to_sym] = true
            end
        end

        i += 1
    }
    total = i

    data = {
        :result=>occurrences,
        :query=>query,
        :stats=>{
            :eoo=>eoo,
            :aoo=>aoo,
            :total=>total,
            :valid=>valid,
            :invalid=>invalid,
            :reviewed=>reviewed,
            :validated=>validated
        }
    }

    view :search,data 
end

post '/occurrences/:id/sig' do
    doc = http_get("#{settings.config[:datahub]}/cncflora2/#{params[:id]}")

    if !doc.has_key?("validation") 
        doc["validation"] = {}
    end

    doc[:georeferencedBy] = session[:user]["name"]
    doc["georeferenceVerificationStatus"] = params[:status]
    doc["georeferenceRemarks"] = params[:comment]
    doc["decimalLatitude"] = params[:latitude].to_f
    doc["decimalLongitude"] = params[:longitude].to_f
    if params[:valid] && params[:valid].length >= 1
        doc["validation"]["status"] = params[:valid]
    end

    r = http_post("#{settings.config[:datahub]}/cncflora2",doc)

    redirect "#{settings.config[:base]}/search?q=#{URI.encode( params[:q] )}#occ-#{params[:id]}-unit"
end

post '/occurrences/:id/analysis' do
    doc = http_get("#{settings.config[:datahub]}/cncflora2/#{params[:id]}")

    doc["comments"] = params[:comment]

    r = http_post("#{settings.config[:datahub]}/cncflora2",doc)
    redirect "#{settings.config[:base]}/search?q=#{URI.encode( params[:q] )}#occ-#{params[:id]}-unit"
end

post '/occurrences/:id/validate' do
    doc = http_get("#{settings.config[:datahub]}/cncflora2/#{params[:id]}")

    doc["validation"] = {
        "status"=>params[:status],
        "reason"=>params[:reason],
        "remarks"=>params[:comment],
        "by"=>session[:user]["name"]
    }

    doc["occurrenceStatus"] = params[:presence]

    r = http_post("#{settings.config[:datahub]}/cncflora2",doc)
    redirect "#{settings.config[:base]}/search?q=#{URI.encode( params[:q] )}#occ-#{params[:id]}-unit"
end

