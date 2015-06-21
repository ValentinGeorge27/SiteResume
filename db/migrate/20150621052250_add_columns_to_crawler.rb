class AddColumnsToCrawler < ActiveRecord::Migration
  def change
    add_column :crawlers, :url_name, :string
    add_column :crawlers, :terms, :text
    add_column :crawlers, :start_time, :datetime
    add_column :crawlers, :end_time, :datetime
    add_column :crawlers, :duration, :string
  end
end
