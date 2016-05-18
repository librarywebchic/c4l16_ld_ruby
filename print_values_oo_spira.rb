require './model/bib'
require './model/author'
require './model/subject'
require './model/client_request_error'

url = 'http://www.worldcat.org/oclc/82671871'

bib = Bib::find(url)
if bib.class == ClientRequestError
  puts bib.response_code
  puts bib.response_body
else
  puts bib.name
  puts bib.author.name
  bib.subjects.each { |subject|
    if subject.name
      puts subject.name
    else
      puts subject.id
    end 
  }
end  