
post '/occurrences/:id/sig' do
    require_logged_in
    
    doc = http_get("#{settings.config[:couchdb]}/#{params[:id]}")

    if !doc.has_key?("validation") 
        doc["validation"] = {}
    end

    doc[:georeferencedBy] = session[:user]["name"]
    doc["georeferenceVerificationStatus"] = params[:status]
    doc["georeferenceRemarks"] = params[:comment]
    doc["decimalLatitude"] = params[:latitude].to_f
    doc["decimalLongitude"] = params[:longitude].to_f

    doc["metadata"]["modified"] = Time.now.to_i

    if !doc["metadata"].has_key?("contributor") || !doc["metadata"]["contributor"].match(session[:user]['name']) then
      doc["metadata"]["contributor"] = "#{session[:user]['name']} ; #{doc["metadata"]["contributor"]}"
      doc["metadata"]["contact"] = "#{session[:user]['email']} ; #{doc["metadata"]["contact"]}"
    end

    r = http_post("#{settings.config[:couchdb]}",doc)

    redirect "#{settings.config[:base]}/search?q=#{URI.encode( params[:q] )}#occ-#{params[:id]}-unit"
end

post '/occurrences/:id/analysis' do
    require_logged_in

    doc = http_get("#{settings.config[:couchdb]}/#{params[:id]}")

    doc["comments"] = params[:comments]
    doc["identificationQualifier"] = params[:identificationQualifier]

    doc["metadata"]["modified"] = Time.now.to_i

    if !doc["metadata"].has_key?("contributor") || !doc["metadata"]["contributor"].match(session[:user]['name']) then
      doc["metadata"]["contributor"] = "#{session[:user]['name']} ; #{doc["metadata"]["contributor"]}"
      doc["metadata"]["contact"] = "#{session[:user]['email']} ; #{doc["metadata"]["contact"]}"
    end

    r = http_post("#{settings.config[:couchdb]}",doc)
    redirect "#{settings.config[:base]}/search?q=#{URI.encode(params[:q])}#occ-#{params[:id]}-unit"
end

post '/occurrences/:id/validate' do
    require_logged_in

    doc = http_get("#{settings.config[:couchdb]}/#{params[:id]}")
    puts session["user"]
   

    doc["validation"] = {
        "taxonomy"=>params[:taxonomy],
        "georeference"=>params[:georeference],
        "native"=>params[:native],
        "presence"=>params[:presence],
        "duplicated"=>params[:duplicated],
        "cultivated"=>params[:cultivated],
        "remarks"=>params[:comment],
        "by"=>session[:user]["name"]
    }

    doc["occurrenceStatus"] = params[:presence]

    doc["metadata"]["modified"] = Time.now.to_i

    if !doc["metadata"].has_key?("contributor") || !doc["metadata"]["contributor"].match(session[:user]['name']) then
      doc["metadata"]["contributor"] = "#{session[:user]['name']} ; #{doc["metadata"]["contributor"]}"
      doc["metadata"]["contact"] = "#{session[:user]['email']} ; #{doc["metadata"]["contact"]}"
    end

    r = http_post("#{settings.config[:couchdb]}",doc)
    redirect "#{settings.config[:base]}/search?q=#{URI.encode( params[:q] )}#occ-#{params[:id]}-unit"
end

