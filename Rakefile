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

require 'digest'
require 'json'
require 'test/unit'
require 'sequel'
require_relative 'lib/helper.rb'

include Test::Unit::Assertions

BACKUP_FOLDER = ENV['BACKUP_FOLDER'] || '/mnt/go_server/go-server/artifacts/serverBackups'
BACKUP_DOWNLOAD_FOLDER = ENV['BACKUP_DOWNLOAD_FOLDER'] ||  './go_server_backup'
BACKUP_SERVER_URL = ENV['BACKUP_SERVER_URL']
SNAPSHOT = {:MD5 => {},:TABLES => {}}

class Redhat
  include Rake::DSL if defined?(Rake::DSL)

  def install(pkg)
    sh("yum install --assumeyes #{pkg}")
  end

  def uninstall(pkg)
    sh("yum remove --assumeyes #{pkg}")
  end
end

task :restore do
  clean_create_dir(BACKUP_DOWNLOAD_FOLDER)
  sh %Q{wget -q -r -nH -nd -np -R "index.html*" #{BACKUP_SERVER_URL}/#{Time.now.strftime("%d-%m-%Y")}/ -P #{BACKUP_DOWNLOAD_FOLDER}/}
  %w{db.zip config-repo.zip config-dir.zip}.each{|f|
    snapshot = JSON.parse(File.read("#{BACKUP_DOWNLOAD_FOLDER}/snapshot.json"))
    assert snapshot["MD5"][f] == Digest::MD5.hexdigest(File.read "#{BACKUP_DOWNLOAD_FOLDER}/#{f}")
  }
  Redhat.new.install("go-server-#{server_version}")
  %w{h2db config.git}.each {|fld| mkdir_p "/var/lib/go-server/db/#{fld}"}
  {"db.zip" => "/var/lib/go-server/db/h2db/",  "config-dir.zip" => "/etc/go/","config-repo.zip" => "/var/lib/go-server/db/config.git/"}.each do |file, dest|
    restore_files("#{BACKUP_DOWNLOAD_FOLDER}/#{file}", dest)
  end

  DB = Sequel.connect("jdbc:h2:file:/var/lib/go-server/db/h2db/cruise;user=sa")
  DB["SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='TABLE'"].each{|t|
    table = t[:table_name]
    snapshot = JSON.parse(File.read("#{BACKUP_DOWNLOAD_FOLDER}/snapshot.json"))
    assert snapshot["TABLES"][table] == DB[table.to_sym].count.to_s
  }

  sh %Q{service go-server start}

end

task :run_test do
  wait_to_start("http://localhost:8153/go/pipelines")
end

task :cleanup do
  Redhat.new.uninstall("go-server-#{server_version}")
  rm_rf "/var/lib/go-server"
  rm_rf "/var/log/go-server"
  rm_rf "/etc/go"
end

task :backup_snapshot do

  Dir["#{BACKUP_FOLDER}/**/*.zip"].each {|f| SNAPSHOT[:MD5].merge!(f.split('/').last.to_sym => Digest::MD5.hexdigest(File.read "#{f}"))}
  clean_create_dir("#{Dir.tmpdir}/db")
  unzipfile "#{BACKUP_FOLDER}/**/db.zip","#{Dir.tmpdir}/db"
  DB = Sequel.connect("jdbc:h2:file:#{Dir.tmpdir}/db/cruise;user=sa")
  DB["SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='TABLE'"].each{|t|
    table = t[:table_name]
    SNAPSHOT[:TABLES].merge!(table.to_sym => "#{DB[table.to_sym].count}")
  }
  open("#{BACKUP_FOLDER}/snapshot.json", 'w') do |file|
    file.write(SNAPSHOT.to_json)
  end
  sh("mv #{BACKUP_FOLDER}/snapshot.json #{BACKUP_FOLDER}/backup_*/")

end

task :restore_test => [:restore, :run_test, :cleanup]
