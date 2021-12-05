require 'sqlite3'
require 'date'

data_root = '/Users/luke/library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data'
db = SQLite3::Database.new "#{data_root}/database.sqlite"

# Bear stores it's timestamps using unixepoch format with it's own start time.
# The offset value I've determined (978307200) seems to be Jan 1, 2001 12:00:00 AM
notes_query = <<-SQL
  select datetime(ZCREATIONDATE + 978307200, 'unixepoch'), ZTITLE, ZTEXT from ZSFNOTE
  where ZTRASHED = 0
    and ZPERMANENTLYDELETED = 0
    and ZTEXT LIKE '%project-slime%'
SQL

db.execute(notes_query) do |row|
  file_name = "#{DateTime.parse(row[0]).strftime('%Y%m%d%H%M')} #{row[1]}"
  text = row[2]
#   puts file_name
#   puts text

  # TODO: search each file for image references and copy the images into the zettel directory
  images = text.match(/\[image:.*\]/)
  images.each do |image|

    # text.gsub!(image, )
  end


  # TODO?: search each file for links to other notes and modify them to properly link the note
end