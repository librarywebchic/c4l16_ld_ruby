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
  Spira.repository = RDF::Repository.new.from_rdfxml(response)
  
  #name
  puts Spira.repository.query(:subject => RDF::URI.new(url), :predicate => RDF::URI.new('http://schema.org/name')).first.object.to_s
  #author
  authors = Spira.repository.query(:subject => RDF::URI.new(url), :predicate => RDF::URI.new('http://schema.org/author'))
  authors.each { |author|
      author_name = Spira.repository.query(:subject => author.object, :predicate => RDF::URI.new('http://schema.org/name')).first
      puts author_name.object
      }
  
  creators = Spira.repository.query(:subject => RDF::URI.new(url), :predicate => RDF::URI.new('http://schema.org/creator'))
  creators.each { |creator|
      creator_name = Spira.repository.query(:subject => creator.object, :predicate => RDF::URI.new('http://schema.org/name')).first
      puts creator_name.object
      }
        
  #about
  subjects = Spira.repository.query(:subject => RDF::URI.new(url), :predicate => RDF::URI.new('http://schema.org/about'))
  subjects.each { |subject|
      subject_name = Spira.repository.query(:subject => subject.object, :predicate => RDF::URI.new('http://schema.org/name')).first
        if subject_name
          puts subject_name.object
        else
          puts subject.object
        end
      
    }
  
  #description
  descriptions = Spira.repository.query(:subject => RDF::URI.new(url), :predicate => RDF::URI.new('http://schema.org/description'))
  descriptions.each { |description|
    puts description.object
  }
  
else
  puts response.code
  puts response
end