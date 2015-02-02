
require 'rest-client'

get '/:db/upload' do
    require_logged_in

    view :upload,{:db=>params[:db]}
end

post '/:db/upload' do
    require_logged_in

    errors = []
    file = "./public/uploads/#{SecureRandom.uuid()}"
    json = ""

    begin
        if params.has_key?("file") 
            # convert to json
            json = RestClient.post "#{settings.dwc_services}/api/v1/convert?from=#{params["type"]}&to=json&fixes=true", 
                                params["file"][:tempfile].read, :content_type => params["file"][:type], :accept => :json

            if json[0] != '[' # cause it must be an array back
                errors.push json
            else
                # validate
                validation = RestClient.post "#{settings.dwc_services}/api/v1/validate", json,
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
                    #geojson = RestClient.post "#{settings.dwc_services}/api/v1/convert?from=json&to=geojson", json,
                    #                            :content_type => params["file"][:type], :accept => :json
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
        view :upload, {:errors=>errors,:has_errors=>has_errors,:db=>params[:db]}
    else
        #puts json
        data = JSON.parse(json)
        count = data.length
        species = []

        data.each {|occ|
            species.push occ["scientificName"]
            occ["_id"] = occ["occurrenceID"]
            occ["metadata"] = {
              "type" => "occurrence",
              "created" => Time.now.to_i,
              "modified" => Time.now.to_i,
              "creator" => session[:user]["name"],
              "contributor" => session[:user]["name"], 
              "contact" => session[:user]["email"]
            }
        }
        r=http_post("#{settings.couchdb}/#{params[:db]}/_bulk_docs",{"docs"=> data});

        index_bulk(params[:db],data)

        view :inserted, {:count=>count,:species=>species.uniq,:db=>params[:db]}
    end
end

