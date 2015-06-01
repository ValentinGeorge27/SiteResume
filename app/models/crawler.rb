require 'uri/http'
require 'unicode_utils'

class Crawler < ActiveRecord::Base

  def self.check_domain_match(url1, url2)
    url1 = 'http://' + url1 unless url1.match(/^(http|https):\/\//)
    url2 = 'http://' + url2 unless url2.match(/^(http|https):\/\//)

    domain1 = PublicSuffix.parse(URI.parse(url1).host).domain
    domain2 =  PublicSuffix.parse(URI.parse(url2).host).domain

    if domain1.eql?domain2
      return true
    else
      return false
    end
  end

  def self.add_page_to_docs(page, docs)
    page_for_doc = ActionController::Base.helpers.strip_tags(page.body.to_s).encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "?")
    page_for_doc.squish!
    page_for_doc.gsub!(/\n\n+/, "\n")
    tokens = %w(a an the and the to a by  quot = + of to de si  )

    words = page_for_doc.scan(/\w+/)
    key_words = words.select { |word| !tokens.include?(word) }

    page_for_doc = key_words.join(' ')
    doc = TfIdfSimilarity::Document.new(page_for_doc)
    docs << doc
    doc
  end

  def self.tf_idf_for_page(doc, docs)
    model = TfIdfSimilarity::TfIdfModel.new(docs, :library => :narray)

    tfidf_by_term = {}
    doc.terms.each do |term|
      tfidf_by_term[term] = model.tfidf(doc, term)
    end
    tfidf_by_term
  end

end
