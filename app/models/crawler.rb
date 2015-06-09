require 'uri/http'
require 'unicode_utils'

class Crawler < ActiveRecord::Base

  STOP_WORDS_EN = %w(a cannot into our thus about co is ours to above could it ourselves together across down its out too after during itself over toward afterwards each last own towards again eg latter per under against either latterly perhaps until all else least rather up almost elsewhere less same upon alone enough ltd seem us along etc many seemed very already even may seeming via also ever me seems was although every meanwhile several we always everyone might she well among everything more should were amongst everywhere moreover since what an except most so whatever and few mostly some when another first much somehow whence any for must someone whenever anyhow former my something where anyone formerly myself sometime whereafter anything from namely sometimes whereas anywhere further neither somewhere whereby are had never still wherein around has nevertheless such whereupon as have next than wherever at he no that whether be hence nobody the whither became her none their which because here noone them while become hereafter nor themselves who becomes hereby not then whoever becoming herein nothing thence whole been hereupon now there whom before hers nowhere thereafter whose beforehand herself of thereby why behind him off therefore will being himself often therein with below his on thereupon within beside how once these without besides however one they would between i only this yet beyond ie onto those you both if or though your but in other through yours by inc others throughout yourself can indeed otherwise thru yourselves)


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
    tokens = %w( de si  )

    words = page_for_doc.scan(/\w+/)
    key_words = words.select { |word| !STOP_WORDS_EN.include?(word) }

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
