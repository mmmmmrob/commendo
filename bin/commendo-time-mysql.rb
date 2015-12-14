#!/usr/bin/env ruby

require 'redis'
require 'commendo'
require 'progressbar'

key_base = ARGV[0]
limit = ARGV[1].to_i

Commendo.config do |config|
  config.backend = :mysql
  config.host = 'localhost'
  config.port = 3306
  config.database = 'commendo_test'
  config.username = 'commendo'
  config.password = 'commendo123'
end
cs = Commendo::ContentSet.new(key_base: key_base)

$stderr.puts "Selecting #{limit} random names to use for #{key_base}"
client = Mysql2::Client.new(Commendo.config.to_hash)
names_to_query = client.query("SELECT DISTINCT name FROM Resources WHERE keybase = '#{key_base}' ORDER BY RAND() LIMIT #{limit}")
names_to_query = names_to_query.map { |r| r['name'] }

def time_this
  start = Time.now
  yield
  finish = Time.now
  finish.to_f - start.to_f
end

pbar = ProgressBar.new('Querying similar_to', names_to_query.length)
times = names_to_query.map do |name|
  pbar.inc
  time_this { cs.similar_to(name) }
end
pbar.finish
mean = times.inject(0, :+) / times.length.to_f
$stderr.puts "Mean timing = #{mean.round(3)}"
times.map! { |time| time.round(2) }
times = times.group_by { |time| time }
times = Hash[times.map { |time, times| [time, times.length] }]

puts times.map { |time, count| "#{key_base}\t#{time}\t#{count}" }