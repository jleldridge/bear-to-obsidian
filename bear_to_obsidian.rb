require 'sqlite3'
require 'date'
require 'fileutils'

data_root = '/Users/luke/library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data'
db = SQLite3::Database.new "#{data_root}/database.sqlite"
zettel_directory = '/Users/luke/Library/Mobile Documents/iCloud~md~obsidian/Documents/bear-to-zettel'
Dir.mkdir "#{zettel_directory}/images" unless File.directory?("#{zettel_directory}/images")

ignore_list = ['.DS_Store']


# Bear stores it's timestamps using unixepoch format with it's own start time.
# The offset value I've determined (978307200) seems to be Jan 1, 2001 12:00:00 AM
notes_query = <<-SQL
  select datetime(ZCREATIONDATE + 978307200, 'unixepoch'), ZTITLE, ZTEXT from ZSFNOTE
  where ZTRASHED = 0
    and ZPERMANENTLYDELETED = 0
SQL

used_file_names = {}
note_links = {}

db.execute(notes_query) do |row|
  text = row[2]

  images = text.scan(/\[image:.*\]/)
  images.each do |image|
    # copy image file to zettel directory
    rel_image_path = "#{image[7...image.length-1]}"
    new_image_name = rel_image_path.gsub('/', '_')
    FileUtils.cp("#{data_root}/Local Files/Note Images/#{rel_image_path}", "#{zettel_directory}/images/#{new_image_name}")

    # sub in markdown style link, with image in images directory
    text = text.gsub!(image, "![image](images/#{new_image_name})")
  end

  new_note_name = if row[1].empty? 
                    "#{DateTime.parse(row[0]).strftime('%Y%m%d%H%M')}.md"
                  else
                    "#{DateTime.parse(row[0]).strftime('%Y%m%d%H%M')} #{row[1]}.md"
                  end

  if !used_file_names[new_note_name].nil?
    suffix = used_file_names[new_note_name]
    used_file_names[new_note_name] += 1
    new_note_name = "#{new_note_name[0...-3]}-#{suffix}.md"
  else
    used_file_names[new_note_name] = 1
  end

  new_note_name = new_note_name.gsub('/', 'or')

  File.open("#{zettel_directory}/#{new_note_name}", 'w') { |f| f.write(text) }
  note_links[row[1]] = new_note_name
end

# Parse wiki-links from files and replace them with markdown links
Dir.entries("#{zettel_directory}").each do |file|
  next if File.directory?("#{zettel_directory}/#{file}") || ignore_list.include?(file)

  contents = File.read("#{zettel_directory}/#{file}")
  puts file
  wiki_links = contents.scan(/\[\[.*\]\]/)

  wiki_links.each do |link|
    next if !note_links[link[2...-2]]

    puts link

    contents = contents.gsub(link, "[#{link[2...-2]}](#{note_links[link[2...-2]]})")
  end

  File.open("#{zettel_directory}/#{file}", 'w') { |f| f.write(contents) }
end