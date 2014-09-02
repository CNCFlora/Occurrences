
get '/' do
    data = []

    if session[:logged]

        ents=[]

        session[:user]["roles"].each {|r|
            if r.has_key? "entities" then
                r["entities"].each {|e|
                    ents.push(e.upcase)
                }
            end
        }

        query = "NOTHING"
        #puts ents

        if ents.length >= 1 then
            query =  "taxonomicStatus:\"accepted\""
            query << " AND ( "
            ents.each{ |e| query << " \"#{e}\" " }
            query << " ) "
        end

        families = [];

        #puts query

        search("taxon",query)
            .each { |e| families.push e['family'] }

        #puts families

        families.uniq.each {|f|
            puts "family #{f}"
            taxon = {
                :family=>f,
                :reviewed=>0,
                :not_reviewed=>0,
                :validated=>0,
                :not_validated=>0,
                :valid=>0,
                :invalid=>0,
                :total=>0
            }

            occs=[]
            names=[]
            search("taxon","family:\"#{f}\" AND taxonomicStatus:\"accepted\" AND (taxonRank:\"species\" OR taxonRank:\"variety\" OR taxonRank:\"subspecies\")")
                .each {|s|
                    if ents.include?(s["scientificNameWithoutAuthorship"].upcase)  or ents.include?(s["family"].upcase)
                        names.push(s['scientificNameWithoutAuthorship'])
                        search("taxon","taxonomicStatus:\"synonym\" AND acceptedNameUsage:\"#{s['scientificNameWithoutAuthorship']}*\"")
                        .each {|ss| names.push ss['scientificNameWithoutAuthorship']}
                    end
                }

            search("occurrence","\"#{ names.select {|n| n != nil }.join("\" OR \"") }\"")
                .each {|occ|
                    taxon[:total] += 1;

                    if occ.has_key?("georeferenceVerificationStatus") 
                        taxon[:reviewed] += 1;
                    else
                        taxon[:not_reviewed] += 1;
                    end

                    if occ.has_key?("validation")
                        if occ["validation"].has_key?("by")
                            taxon[:validated] += 1
                        else
                            taxon[:not_validated] += 1
                        end
                    else
                        taxon[:not_validated] += 1
                    end
                }
            
            data.push(taxon)

        }

    end

    view :index,{:data=>data}
end
