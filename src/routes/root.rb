
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
        search(settings.db,query).each {|occ|
            taxon = species[occ["scientificName"]]
            if taxon 
                taxon[:total] += 1;

                if occ.has_key?("georeferenceVerificationStatus") 
                    taxon[:reviewed] += 1;
                end

                if occ.has_key?("validation")
                    if occ["validation"].has_key?("status")
                        if occ["validation"]["status"] === 'valid'
                            taxon[:validated] += 1
                            taxon[:valid] += 1
                        elsif occ["validation"]["status"] === 'invalid'
                            taxon[:validated] += 1
                            taxon[:invalid] += 1
                        end
                    end
                end
            end
        }
    end

    view :index,{:species=>species}
end
