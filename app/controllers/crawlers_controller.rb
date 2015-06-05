require 'open-uri'
require 'uri'
require 'cgi'
require 'narray'
require 'tf-idf-similarity'

class CrawlersController < ApplicationController
  before_action :set_crawler, only: [:show, :edit, :update, :destroy]

  # GET /crawlers
  # GET /crawlers.json
  def index
    @crawlers = Crawler.all
  end

  # GET /crawlers/1
  # GET /crawlers/1.json
  def show
  end

  # GET /crawlers/new
  def new
    @crawler = Crawler.new
  end

  # GET /crawlers/1/edit
  def edit
  end

  # POST /crawlers
  # POST /crawlers.json
  def create
    @crawler = Crawler.new(crawler_params)

    respond_to do |format|
      if @crawler.save
        format.html { redirect_to @crawler, notice: 'Crawler was successfully created.' }
        format.json { render :show, status: :created, location: @crawler }
      else
        format.html { render :new }
        format.json { render json: @crawler.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /crawlers/1
  # PATCH/PUT /crawlers/1.json
  def update
    respond_to do |format|
      if @crawler.update(crawler_params)
        format.html { redirect_to @crawler, notice: 'Crawler was successfully updated.' }
        format.json { render :show, status: :ok, location: @crawler }
      else
        format.html { render :edit }
        format.json { render json: @crawler.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /crawlers/1
  # DELETE /crawlers/1.json
  def destroy
    @crawler.destroy
    respond_to do |format|
      format.html { redirect_to crawlers_url, notice: 'Crawler was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def search_site
    unless search_params.nil?
      page_name = search_params

      links = Set.new
      redirect_links = Set.new
      docs = []
      initial_page =  MetaInspector.new(page_name)
      flag = true

      Anemone.crawl(initial_page.url, :verbose => true, :obey_robots_txt => true, :depth_limit=> 5, :crawl_subdomains => true) do |anemone|
        anemone.storage = Anemone::Storage.Redis
=begin
        anemone.after_crawl do |test|
          test.each_value do |page|
            puts page.url
          end
        end
http://datascience.stackexchange.com/questions/678/what-are-some-standard-ways-of-computing-the-distance-between-documents
=end
        anemone.on_every_page do |page|
          if page.code.to_i >= 200 && page.code.to_i < 400

            unless redirect_links.include? page.url
=begin
            if flag
            puts page.url
              doc = Crawler.add_page_to_docs(page,docs)
              terms = Crawler.tf_idf_for_page(doc, docs)
              puts terms
            end
=end
            links << page.url
          end

=begin
          unless page.redirect_to.nil?
            redirect_url = URI.parse(URI.encode(page.redirect_to.to_s)).to_s
            if Crawler.check_domain_match(initial_page.url, redirect_url)
              unless links.include? redirect_url
                redirect_links << redirect_url
                  Anemone.crawl(redirect_url, :discard_page_bodies => true,:obey_robots_txt => true, :depth_limit => 5) do |anemone_redirect|
                    anemone_redirect.on_every_page do |a_page|
                      if links.include? a_page.url
                        # crawl
                      end
                    end
                  end
              end
            end
          end
=end
        end
        end
      end
=begin
      page.links.all.each do |p|
        open(p) do |f|
          puts f.read
        end
      end
=end

      redirect_to :back
    end
    end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_crawler
      @crawler = Crawler.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def crawler_params
      params[:crawler]
    end

    def search_params
      params[:site_name]
    end
end
