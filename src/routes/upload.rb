
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
                    #File.open("#{file}.json",'w') { |f| f.write(json) }
                    #File.open("#{file}.geojson",'w') { |f| f.write(geojson) }
                end
            end
        else
            errors.push("Must upload a file!")
        end
    rescue Exception => e
        puts "Exception!"
        errors.push e.message
        if e.respond_to? "response"
            puts e.response.to_str
            errors.push e.response.to_str
        end
        puts e.message  
        puts e.backtrace.inspect  
    end

    has_errors = errors.length > 0

    if has_errors 
        view :upload, {:errors=>errors,:has_errors=>has_errors}
    else
        puts json
        data = JSON.parse(json)
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

        r=http_post("#{settings.config[:couchdb]}/#{settings.db}/_bulk_docs",{"docs"=> data});

        view :inserted, {:count=>count,:species=>species.uniq}
    end
end

