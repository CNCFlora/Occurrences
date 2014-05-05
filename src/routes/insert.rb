
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

    http_post("#{settings.config[:couchdb]}/#{settings.db}/_bulk_docs",{"docs"=> data});

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

    http_post("#{settings.config[:couchdb]}/#{settings.db}/_bulk_docs",{"docs"=> data});

    view :inserted, {:count=>count,:species=>species.uniq}
end

