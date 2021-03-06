##########################################################################
# Copyright 2017 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################
  #!/usr/bin/env jruby
require 'rest-client'

require 'json'
require 'nokogiri'
require 'test/unit'
require 'open-uri'
require 'zip'

include Test::Unit::Assertions

def service_status
  puts 'wait for server to come up'
  sh('wget http://localhost:8153/go/about --waitretry=120 --retry-connrefused --quiet -O /dev/null')
end


def wait_to_start(url)
  wait_till_event_occurs_or_bomb 180, "Connect to : #{url}" do
      begin
        break if running?(url)
      rescue Errno::ECONNREFUSED
        p "Connection refused on server ping"
        sleep 5
      end
    end
end

def wait_till_event_occurs_or_bomb(wait_time, message)
      Timeout.timeout(wait_time) do
        loop do
          yield if block_given?
          sleep 5
        end
      end
    rescue Timeout::Error
      raise "The event did not occur - #{message}. Wait timed out"
end


def running?(url)
  begin
    ping(url).code == 200
  rescue => e
    p "Connection refused on server ping"
    false
  end
end

def clean_create_dir(dir)
  rm_rf dir if Dir.exists?(dir)
  mkdir_p dir
end

def ping(url)
  p "Check if server is up & running ... Hitting URL : #{url}"
  RestClient.get("#{url}")
end

def unzipfile(file, dest)
  Zip::File.open(file) do |f|
    f.each do |entry|
      target = Pathname.new(dest) + entry.name
      entry.extract target unless File.exist? target
    end
  end
end

def restore_files(zip_file, dest)
  begin
    rm_rf "tmp" if Dir.exists?("tmp")
    mkdir_p "tmp"
    unzipfile zip_file, "tmp"
    cp_r "tmp/.", dest
  rescue => e
    p "Restoration of #{zip_file} failed with error #{e.message}"
  end
end

def server_version
  filename = Dir.glob("./go_server_backup/**/version.txt").first
  version = File.open(filename, "rb").read
  "#{version.split(" ")[0]}-#{version.split(" ")[1].split("-")[0][1..-1]}"
end
