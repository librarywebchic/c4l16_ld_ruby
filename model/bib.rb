# Copyright 2014 OCLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "equivalent-xml"
require "rdf"
require "rdf/rdfxml"
require 'rest_client'
require "spira"
require "addressable/uri"
require 'rubygems'
 
# == Properties mapped from RDF data
#
# RDF properties are mapped via an ORM style mapping.
# 
# [type] RDF predicate: http://www.w3.org/1999/02/22-rdf-syntax-ns#type; returns: RDF::URI
# [name] RDF predicate: http://schema.org/name; returns: String
# [author] RDF predicate: http://schema.org/author; returns: Enumerable of Author objects
# [subjects] RDF predicate: http://schema.org/about; returns: Enumerable of Subject objects

class Bib < Spira::Base
  
  attr_accessor :response_body, :response_code, :result
  
  property :name, :predicate => RDF::URI.new('http://schema.org/name'), :type => XSD.string
  property :author, :predicate => RDF::URI.new('http://schema.org/creator'), :type => 'Author' 
  has_many :subjects, :predicate => RDF::URI.new('http://schema.org/about'), :type => 'Subject'
  property :type, :predicate => RDF.type, :type => RDF::URI
  
  # call-seq:
  #   id() => RDF::URI
  # 
  # Will return the RDF::URI object that serves as the RDF subject of the current Subject
  def id
    self.subject
  end
  
  def self.find(bib_uri) 
    url = bib_uri 
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
      # Load the data into an in-memory RDF repository, get the Bib 
      Spira.repository = RDF::Repository.new.from_rdfxml(response) 
      bib = Spira.repository.query(:predicate => RDF.type, :object => RDF::URI.new('http://schema.org/CreativeWork')).first
      bib = bib.subject.as(Bib) 
      bib.response_body = response 
      bib.response_code = response.code 
      bib.result = result 
      bib 
       
    else 
      client_request_error = ClientRequestError.new 
      client_request_error.response_body = response 
      client_request_error.response_code = response.code 
      client_request_error.result = result 
      client_request_error 
    end 
  end 
  
end