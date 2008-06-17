#! /usr/bin/env ruby

require 'fileutils'
class DevArchive
  attr_reader :source, :dest, :timestamp
  attr_accessor :interval
  
  def initialize (source, dest, interval)
    @source = File.expand_path source
    @dest = File.expand_path dest
    @interval = interval * 60
  end
  
  def die (message, value=1)
    puts message
    exit value
  end

  def run
    raise "''#{source}' is not a directory" unless File.directory?(source)
    initial_sync_if_needed

    while true do
      sync_if_needed
      sleep @interval
    end
  end
  
  def initial_sync_if_needed
    FileUtils.mkdir_p @dest
    regenerate_timestamp
    system "rsync", "-aqC", @source, File.join(@dest, @timestamp)
    save_timestamp
  end

  def sync_if_needed
    sync if diff
  end
  
  def diff
    %x{diff -x .svn -qbBr #{@source.gsub(' ','\\ ')} #{File.join(last_dir, File.basename(@source)).gsub(' ','\\ ')}}
    $?.exitstatus != 0
  end
  
  def sync
    regenerate_timestamp
    system "rsync", "-aqC", "--link-dest=#{last_dir}", @source, File.join(@dest, @timestamp)
    save_timestamp
  end
  
  def last_dir
    File.join(@dest, File.read(timestamp_file).chomp) if File.exists?(timestamp_file)
  end

  def save_timestamp
    File.open(timestamp_file, "w") { |f| f.puts @timestamp }
  end
  
  def regenerate_timestamp
    @timestamp = Time.now.strftime("%y%m%d_%H%M%S")
  end
  
  def timestamp_file
    File.join(@dest,"TIMESTAMP")
  end
  
  
end

if $0 == __FILE__
  dir = ARGV.shift || "."
  archive = File.join dir, "../dev_archive"
  puts "Will copy #{dir} to #{archive} every minute"
  DevArchive.new(dir, archive, 1).run
end
