#! /usr/bin/ruby
#

require 'pathname'
def die (msg)
  puts msg
  exit 1
end

die "Kommandot måste köras med sudo" unless Process.uid == 0
virtual = ARGV.shift || die("Första argumentet måste vara ett virtuellt hostnamn")
path    = ARGV.shift || die("Andra argumentet måste vara en sökväg")
path    = Pathname.new(path).realpath

die "hostnamnet '#{virtual}' innehåller konstiga tecken" unless virtual =~ /^[-a-z0-9]+$/
die "'#{path}' är inte en katalog" unless path.exist?
die "'#{path}' innehåller mellanslag" if path.to_s.include?(' ')

server_name = "#{virtual}.tobago.local"

File.open "/etc/apache2/users/david.conf", "a" do |f|
#File.open "/Users/david/tmp/david.conf", "a" do |f|
  str = <<EOT

<VirtualHost *:80 *:8000>
    ServerAdmin webmaster.#{virtual}@vrensk.com
    DocumentRoot #{path}
    ServerAlias #{server_name}
    ServerAlias #{virtual}.jobbet.vrensk.com
</VirtualHost>
EOT
  f.puts str
end

File.open "/etc/hosts", "a" do |f|
#File.open "/Users/david/tmp/hosts", "a" do |f|
  f.puts "127.0.0.1 #{server_name}"
end

system "apachectl -k graceful"
