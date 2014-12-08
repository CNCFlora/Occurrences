
get '/:db/families' do
    require_logged_in

    families=[]

    r = search(params[:db],"taxon","taxonomicStatus:\"accepted\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")
    r.each{|taxon|
        families.push taxon["family"].upcase
    }

    view :families, {:families=>families.uniq.sort,:db=>params[:db]}
end

get '/:db/family/:family' do
    require_logged_in

    family = params[:family]
    species= search(params[:db],"taxon","family:\"#{family}\" AND taxonomicStatus:\"accepted\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\")")
                    .sort {|t1,t2| t1["scientificName"] <=> t2["scientificName"] }

    if session[:logged]
        ents=[]
        session[:user]["roles"].each {|c|
          if c["context"] == params[:db] then
            c["roles"].each {|r|
              if r.has_key? "entities" then
                r["entities"].each {|e|
                  ents.push(e.downcase)
                }
              end
            }
          end
        }
        species.each {|s|
            s[ "permission" ] = (ents.include?(s["scientificNameWithoutAuthorship"].downcase) or ents.include?(s["family"].downcase))
        }
    end

    view :family, {:species=>species,:family=>family,:db=>params[:db]}
end


get '/:db/specie/:name' do
    require_logged_in

    query = "\"#{params[:name]}\""

    search(params[:db],"taxon","acceptedNameUsage:\"#{params[:name]}\"").each {|t|
        query << " OR \"#{t["scientificNameWithoutAuthorship"]}\""
    }

    if params[:json]
      redirect "#{settings.config[:base]}/#{params[:db]}/search?json=true&q=#{URI.encode( query )}"
    else
      redirect "#{settings.config[:base]}/#{params[:db]}/search?q=#{URI.encode( query )}"
    end
end

