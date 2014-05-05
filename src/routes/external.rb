
get '/editor' do
    query = (params[:q] || "*").gsub("&quot","\"")
    occurrences = search(settings.db,"metadata.type=\"occurrence\" AND (#{query})")
    editor = settings.config[:recline_editor_url];
    puts settings.config
    view :recline,{:occurrences=>occurrences,:query=>query,:editor=>editor}
end

get "/json" do
    query = (params[:q] || "*").gsub("&quot","\"")

    occurrences = []
    search(settings.db,"metadata.type=\"occurrence\" AND (#{query})").each {|occ|
        occ["decimalLatitude"] = occ["decimalLatitude"].to_f
        occ["decimalLongitude"] = occ["decimalLongitude"].to_f
        occurrences << occ;
    }

    r=""
    if params[:callback]
        r << params[:callback]
        r << "("
    end
    r << occurrences.to_json
    if params[:callback]
        r << ");"
    end
    r
end

post "/json" do
    data = JSON.parse(params[:data]) 
    keys = []
    data.each{|r| keys << r['occurrenceID']}
    r = http_post("#{settings.config[:couchdb]}/#{settings.db}/_all_docs",{:keys=>keys})
    docs = []

    data.each{ |occ|
        r["rows"].each {|row|
            if row["id"] == occ["occurrenceID"]
                occ["_rev"] = row["value"]["rev"]
                occ["_id"] = row["id"]
                docs << occ
            end
        }
    }
    r=http_post("#{settings.config[:couchdb]}/#{settings.db}/_bulk_docs",{"docs"=> docs});

    query = URI.encode(params[:q].gsub("&quot;","\""))
    redirect "#{settings.config[:base]}/search?q=#{query}"
end

