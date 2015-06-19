require 'open-uri'
require 'uri'
require 'cgi'
require 'narray'
require 'tf-idf-similarity'
require 'matrix'

class CrawlersController < ApplicationController


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

      docs = []
      models = []
      initial_page =  MetaInspector.new(page_name)
      flag = true
      links = Set.new
      count = 0
      terms_sum = {}
      ext = %w(flv swf png jpg gif asx zip rar tar 7z gz jar js css dtd xsd ico raw mp3 mp4 wav wmv ape aac ac3 wma aiff mpg mpeg avi mov ogg mkv mka asx asf mp2 m1v m3u f4v pdf doc xls ppt pps bin exe rss xml)

      Pusher.url = "http://bf3efe4f2a538719f902:db72afa11aacfefef390@api.pusherapp.com/apps/125528"

      Anemone.crawl(initial_page.url,:max_page_queue_size => 100, :depth_limit=> 5, :skip_query_strings => true, :read_timeout => 10, :crawl_subdomains => true) do |anemone|
        anemone.skip_links_like /\.#{ext.join('|')}$/
        anemone.on_every_page do |page|
          if page.code.to_i >= 200 && page.code.to_i < 400
            unless links.include? page.url
                  doc = Crawler.add_page_to_docs(page,docs, page_name)
                  unless doc.blank?
                    #models = Crawler.update_models(docs, models)
                    terms = Crawler.tf_idf_for_page(doc,docs, models)
                    puts terms

                    Pusher['test_channel'].trigger('my_event', {
                        message: terms
                    })
                    #send_data_to_browser
                    terms_sum = Crawler.add_to_terms_sum(terms, terms_sum)
                  end
              links << page.url
            end
          end
        end
      end
      puts terms_sum.sort_by {|k,v| v}.reverse
    end
  end


=begin
  def send_data_to_browser
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 300)
    begin
      sse.write({ :message => 'test'})
      sleep 1
    rescue IOError
    ensure
      sse.close
    end
    render nothing: true
  end
=end


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
