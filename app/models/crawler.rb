require 'uri/http'
require 'unicode_utils'

class Crawler < ActiveRecord::Base

  STOP_WORDS_EN = %w(a cannot into our thus about co is ours to above could it ourselves together across down its out too after during itself over toward afterwards each last own towards again eg latter per under against either latterly perhaps until all else least rather up almost elsewhere less same upon alone enough ltd seem us along etc many seemed very already even may seeming via also ever me seems was although every meanwhile several we always everyone might she well among everything more should were amongst everywhere moreover since what an except most so whatever and few mostly some when another first much somehow whence any for must someone whenever anyhow former my something where anyone formerly myself sometime whereafter anything from namely sometimes whereas anywhere further neither somewhere whereby are had never still wherein around has nevertheless such whereupon as have next than wherever at he no that whether be hence nobody the whither became her none their which because here noone them while become hereafter nor themselves who becomes hereby not then whoever becoming herein nothing thence whole been hereupon now there whom before hers nowhere thereafter whose beforehand herself of thereby why behind him off therefore will being himself often therein with below his on thereupon within beside how once these without besides however one they would between i only this yet beyond ie onto those you both if or though your but in other through yours by inc others throughout yourself can indeed otherwise thru yourselves)

  def self.add_page_to_docs(page, docs, page_name)

    page_for_doc = ActionController::Base.helpers.sanitize(page.body.to_s)
    page_for_doc = ActionController::Base.helpers.strip_tags(page_for_doc).encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "?")
    page_for_doc.squish!
    page_for_doc.gsub!(/\n\n+/, "\n")

    tokens = %w(la te ron asa da cu nu te si va ce cum unde o un ala ul urile a de la cu peste langa sub catre prin contra in pe fara pentru din asemenea )
    lista_pronume = %w(asa noastra toate tau eu tu el ea noi voi ei ele mei sau sa dansul acesta asta aceea același cine ce care cât care ceea cine unul unii cineva altul oricare vreunul)

    page_name_terms = page_name.split('.')

    words = page_for_doc.scan(/\w+/)
    key_words = words.select { |word| !STOP_WORDS_EN.include?(word) }
    key_words = key_words.select { |word| !tokens.include?(word) }
    key_words = key_words.select { |word| !lista_pronume.include?(word) }
    key_words = key_words.select { |word| !page_name_terms.include?(word) }
    key_words = key_words.select { |word| word.length > 1 }

    page_for_doc = key_words.join(' ')

    if page_for_doc.blank?
      doc = []
    else
      doc = TfIdfSimilarity::Document.new(page_for_doc)
      docs << doc
      doc
    end
  end

  def self.update_models(docs, models)
    model = models.last

    if model.nil?
      models << TfIdfSimilarity::TfIdfModel.new(docs, :library => :narray)
    else
      if docs.length <= 100
        model = TfIdfSimilarity::TfIdfModel.new(docs, :library => :narray)
      end

      if docs.length.eql? 100
        last_doc = docs.last
        docs = []
        docs << last_doc
        models << TfIdfSimilarity::TfIdfModel.new(docs, :library => :narray)
      end
    end
    models
  end

  def self.tf_idf_for_page_v2(doc,models)
    tfidf_by_term = {}
    models.each do |model|
      doc.terms.each do |term|
        tfidf_by_term[term] = model.tfidf(doc, term)
      end
    end
    tfidf_by_term.to_hash
  end

  def self.tf_idf_for_page(doc,docs, models)
    model = TfIdfSimilarity::TfIdfModel.new(docs, :library => :narray)

    tfidf_by_term = {}
      doc.terms.each do |term|
        tfidf_by_term[term] = model.tfidf(doc, term)
      end
    tfidf_by_term.to_hash
  end

  def self.add_to_terms_sum(terms, terms_sum)
    terms_sum.merge(terms) { |k, ts_value, t_value| ts_value + t_value }
  end

end
