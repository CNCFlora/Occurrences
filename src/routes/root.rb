
get '/' do
    species = {}

    if session[:logged]

        ents=[]
        session[:user]["roles"].each {|r|
            if r.has_key? "entities" then
                r["entities"].each {|e|
                    ents.push(e)
                }
            end
        }

        query = "NOTHING"

        if ents.length >= 1 then
            query << "(taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\") "
            query << " AND ( "
            ents.each{ |e| query << " \"#{e}\" " }
            query << " ) "
        end

        search("taxon",query).each { |e| 
            spp = {
                :family=>e["family"],
                :scientificName=>e["scientificName"],
                :scientificNameWithoutAuthorship=>e["scientificNameWithoutAuthorship"],
                :reviewed=>0,
                :not_reviewed=>0,
                :validated=>0,
                :not_validated=>0,
                :valid=>0,
                :invalid=>0,
                :total=>0
            }
            species[e["scientificNameWithoutAuthorship"]] = spp
            species[e["scientificName"]] = spp
        }

        query = "\"#{species.keys.join("\" OR \"")}\""
        search("occurrence",query).each {|occ|
            taxon = species[occ["scientificName"]] || species[occ["scientificNameWithoutAuthorship"]]

            if taxon 
                taxon[:total] += 1;

                if occ.has_key?("georeferenceVerificationStatus") 
                    taxon[:reviewed] += 1;
                else
                    taxon[:not_reviewed] += 1;
                end

                if occ.has_key?("validation")
                    if occ["validation"].has_key?("status")
                        if occ["validation"]["status"] === 'valid'
                            taxon[:validated] += 1
                            taxon[:valid] += 1
                        elsif occ["validation"]["status"] === 'invalid'
                            taxon[:validated] += 1
                            taxon[:invalid] += 1
                        else
                            taxon[:not_validated] += 1
                        end
                    end
                end
            end
        }
    end

    view :index,{:species=>species.values}
end
