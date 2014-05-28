
require 'json'
require 'uri'
require 'net/http'

def http_get(uri)
    JSON.parse(Net::HTTP.get(URI(uri)))
end

def http_post(uri,doc) 
    uri = URI.parse(uri)
    header = {'Content-Type'=> 'application/json'}
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = doc.to_json
    response = http.request(request)
    JSON.parse(response.body)
end

def http_put(uri,doc) 
    uri = URI.parse(uri)
    header = {'Content-Type'=> 'application/json'}
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri, header)
    request.body = doc.to_json
    response = http.request(request)
    JSON.parse(response.body)
end

def http_delete(uri)
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Delete.new(uri.request_uri)
    response = http.request(request)
    JSON.parse(response.body)
end

def search(index,query)
    query="scientificName:'Aphelandra longiflora'" unless query != nil && query.length > 0
    result = []
    r = http_get("#{settings.elasticsearch}/#{index}/_search?size=999&q=#{URI.encode(query)}")
    r['hits']['hits'].each{|hit|
        result.push(hit["_source"])
    }
    result
end

def etcd(server)
    config = {:etcd=>server}
    if config[:etcd]
        etcd = http_get("#{config[:etcd]}/v2/keys/?recursive=true") 
        etcd['node']['nodes'].each {|node|
            if node.has_key?('nodes')
                node['nodes'].each {|entry|
                    if entry.has_key?('value') && entry['value'].length >= 1 
                        key = entry['key'].gsub("/","_").gsub("-","_").downcase()[1..-1]
                        config[key.to_sym] = entry['value']
                    end
                }
            end
        }
    end
    config
end

def etcd2settings(server)
    config = etcd(server)
    config.keys.each { |key| set key, config[key] }
    set :config, config
    config
end

