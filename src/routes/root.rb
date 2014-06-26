
get '/' do
    species = {}

    if session[:logged]

        query = "(taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecie\") AND ("
        session[:user]["roles"].each {|r|
            r["entities"].each {|e|
                query << " \"#{e}\" "
            }
        }
        query << ")"

        search("taxon",query).each { |e| 
            species[e["scientificName"]] = {
                :family=>e["family"],
                :scientificName=>e["scientificName"],
                :reviewed=>0,
                :not_reviewed=>0,
                :validated=>0,
                :not_validated=>0,
                :valid=>0,
                :invalid=>0,
                :total=>0
            }
        }

        query = "\"#{species.keys.join("\" OR \"")}\""
        puts query
        search("occurrence",query).each {|occ|
            taxon = species[occ["scientificName"]]

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
