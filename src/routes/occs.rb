
post '/occurrences/:id/sig' do
    doc = http_get("#{settings.config[:couchdb]}/#{settings.db}/#{params[:id]}")

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

    doc["metadata"]["modified"] = Time.now.to_i

    if !doc["metadata"].has_key?("contributor") || !doc["metadata"]["contributor"].match(session[:user]['name']) then
      doc["metadata"]["contributor"] = "#{session[:user]['name']} ; #{doc["metadata"]["contributor"]}"
      doc["metadata"]["contact"] = "#{session[:user]['email']} ; #{doc["metadata"]["contact"]}"
    end

    r = http_post("#{settings.config[:couchdb]}/#{settings.db}",doc)

    redirect "#{settings.config[:base]}/search?q=#{URI.encode( params[:q] )}#occ-#{params[:id]}-unit"
end

post '/occurrences/:id/analysis' do
    doc = http_get("#{settings.config[:couchdb]}/#{settings.db}/#{params[:id]}")

    doc["comments"] = params[:comments]
    doc["identificationQualifier"] = params[:identificationQualifier]

    doc["metadata"]["modified"] = Time.now.to_i

    if !doc["metadata"].has_key?("contributor") || !doc["metadata"]["contributor"].match(session[:user]['name']) then
      doc["metadata"]["contributor"] = "#{session[:user]['name']} ; #{doc["metadata"]["contributor"]}"
      doc["metadata"]["contact"] = "#{session[:user]['email']} ; #{doc["metadata"]["contact"]}"
    end

    r = http_post("#{settings.config[:couchdb]}/#{settings.db}",doc)
    redirect "#{settings.config[:base]}/search?q=#{URI.encode(params[:q])}#occ-#{params[:id]}-unit"
end

post '/occurrences/:id/validate' do
    doc = http_get("#{settings.config[:couchdb]}/#{settings.db}/#{params[:id]}")

    doc["validation"] = {
        "status"=>params[:status],
        "reason"=>params[:reason],
        "remarks"=>params[:comment],
        "by"=>session[:user]["name"]
    }

    doc["occurrenceStatus"] = params[:presence]

    doc["metadata"]["modified"] = Time.now.to_i

    if !doc["metadata"].has_key?("contributor") || !doc["metadata"]["contributor"].match(session[:user]['name']) then
      doc["metadata"]["contributor"] = "#{session[:user]['name']} ; #{doc["metadata"]["contributor"]}"
      doc["metadata"]["contact"] = "#{session[:user]['email']} ; #{doc["metadata"]["contact"]}"
    end

    r = http_post("#{settings.config[:couchdb]}/#{settings.db}",doc)
    redirect "#{settings.config[:base]}/search?q=#{URI.encode( params[:q] )}#occ-#{params[:id]}-unit"
end

