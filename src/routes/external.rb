
get '/:db/editor' do
    require_logged_in

    query = (params[:q] || "*").gsub("&quot","\"")
    occurrences = search(params[:db],"occurrence","#{query}")

    view :recline,{:occurrences=>occurrences,:query=>query,:db=>params[:db]}
end

get "/:db/json" do
    require_logged_in

    query = (params[:q] || "*").gsub("&quot","\"")

    occurrences = []
    search(params[:db],"occurrence","#{query}").each {|occ|
        occ["occurrenceID"] = occ["id"]
        occ["decimalLatitude"] = occ["decimalLatitude"].to_f
        occ["decimalLongitude"] = occ["decimalLongitude"].to_f
        occurrences << occ;
    }

    r=""
    if params[:callback]
        r << params[:callback]
        r << "("
    else
      content_type 'application/json'
    end
    r << occurrences.to_json
    if params[:callback]
        r << ");"
    end
    r
end

post "/:db/json" do
    require_logged_in

    data = JSON.parse(params[:data]) 
    keys = []
    data.each{|r| 
        keys << r['occurrenceID']
        keys << "#{ r['occurrenceID'] }.0"
    }
    r = http_post("#{settings.couchdb}/#{params[:db]}/_all_docs?include_docs=true",{:keys=>keys})
    docs = []

    puts data

    data.each{ |occ|
        r["rows"].each {|row|
          puts row
            if row["id"] == occ["occurrenceID"] || row["id"] == "#{occ["occurrenceID"]}.0"
              puts "got"
                doc = row["doc"]

                occ["metadata"]["modified"] = Time.now.to_i

                if occ["metadata"]["contributor"].nil? then
                  occ["metadata"]["contributor"] = "#{session[:user]['name']}"
                  occ["metadata"]["contact"] = "#{session[:user]['email']}"
                elsif !occ["metadata"]["contributor"].match(session[:user]['name']) then
                  occ["metadata"]["contributor"] = "#{session[:user]['name']} ; #{occ["metadata"]["contributor"]}"
                  occ["metadata"]["contact"] = "#{session[:user]['email']} ; #{occ["metadata"]["contact"]}"
                end

                occ.keys.each {|k|
                  doc[k] = occ[k]
                }

                docs << doc 
            end
        }
    }

    r=http_post("#{settings.couchdb}/#{params[:db]}/_bulk_docs",{"docs"=> docs});
    puts "rrrr=#{r}"
    index_bulk(params[:db],docs)

    query = URI.encode(params[:q].gsub("&quot;","\""))
    redirect "#{settings.base}/#{params[:db]}/search?q=#{query}"
end

