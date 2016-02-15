require "equivalent-xml"
require "rdf"
require "rdf/rdfxml"
require 'rest_client'
require "spira"
require "addressable/uri"
require 'rubygems'
require 'sparql'

url = 'http://www.worldcat.org/oclc/82671871'

# Make the HTTP request for the data
resource = RestClient::Resource.new url
response, result = resource.get(:user_agent => "Example Ruby Linked Data code",
  :accept => 'application/rdf+xml') do |response, request, result|
  [response, result]
end

if result.kind_of? Net::HTTPRedirection
  resource = RestClient::Resource.new response.headers[:location]
  response, result = resource.get(:user_agent => "Example Ruby Linked Data code",
    :accept => 'application/rdf+xml') do |response, request, result|
    [response, result]
  end
end

if result.class == Net::HTTPOK
  # Load the data into an in-memory RDF repository, get the GenericResource and its Bib
  graph = RDF::Repository.new.from_rdfxml(response)
  
  graph.query([RDF::URI(url), RDF::URI("http://schema.org/name"), nil]) do |statement|
    puts statement.object.to_s
  end
  
  graph.query([RDF::URI(url), RDF::URI("http://schema.org/creator")]) do |statement|
    graph.query([statement.object, RDF::URI("http://schema.org/name"), nil] ) do |creator|
      puts creator.object.to_s
    end
  end
  
  graph.query([RDF::URI(url), RDF::URI("http://schema.org/about")]) do |statement|
    about = graph.query([statement.object, RDF::URI("http://schema.org/name"), nil] ) do |about|
      about
    end
    
    if about.count > 0
      puts about.first.object
    else
      puts statement.object
    end
  end
  
  graph.query([RDF::URI(url), RDF::URI("http://schema.org/description")]) do |statement|
    puts statement.object.to_s
  end  
  
else
  puts response.code
  puts response
end