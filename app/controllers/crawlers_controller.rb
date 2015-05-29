require 'open-uri'
require 'uri'
require 'cgi'

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

      initial_page =  MetaInspector.new(page_name)

      Anemone.crawl(initial_page.url, :allow_redirections => true, :verbose => false, :obey_robots_txt => true, :discard_page_bodies => true, :depth_limit=> 5) do |anemone|
        anemone.on_every_page do |page|

          unless redirect_links.include? page.url
            links << page.url
          end

          unless page.redirect_to.nil?
            redirect_url = URI.parse(URI.encode(page.redirect_to.to_s)).to_s
            if Crawler.check_domain_match(initial_page.url, redirect_url)
              puts 'match'
              unless links.include? redirect_url
                redirect_links << redirect_url
                  Anemone.crawl(redirect_url, :discard_page_bodies => true, :depth_limit => 3) do |anemone_redirect|
                    anemone_redirect.on_every_page do |a_page|
                      if links.include? a_page.url
                        puts 'skip_redirect'
                      end
                    end
                  end
              end
            end
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
