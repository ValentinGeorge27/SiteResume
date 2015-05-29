require 'uri/http'
class Crawler < ActiveRecord::Base


  def self.check_domain_match(url1, url2)
    url1 = 'http://' + url1 unless url1.match(/^http:\/\//)
    url2 = 'http://' + url2 unless url2.match(/^http:\/\//)

    uri1= URI.parse(url1)
    uri2 = URI.parse(url2)
    domain1 = PublicSuffix.parse(uri1.host).domain
    domain2 =  PublicSuffix.parse(uri2.host).domain

    if domain1.eql?domain2
      return true
    else
      return false
    end

  end

end
