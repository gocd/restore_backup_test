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
require 'sequel'
#require 'java'
require_relative 'lib/helper.rb'

BACKUP_FOLDER = '/mnt/go_server/go-server/artifacts/serverBackups/backup_*/'
BACKUP_DOWNLOAD_FOLDER = './go_server_backup'
BACKUP_SERVER_URL = ENV['BACKUP_SERVER_URL']
SNAPSHOT = {:MD5 => {},:TABLE => {}}

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
  rm_rf BACKUP_DOWNLOAD_FOLDER if Dir.exists?(BACKUP_DOWNLOAD_FOLDER)
  mkdir_p BACKUP_DOWNLOAD_FOLDER
  sh %Q{wget -q -r -nH -nd -np -R "index.html*" #{BACKUP_SERVER_URL}/#{Time.now.strftime("%d-%m-%Y")}/ -P #{BACKUP_DOWNLOAD_FOLDER}/}
  Redhat.new.install("go-server-#{server_version}")
  restore_files("#{BACKUP_DOWNLOAD_FOLDER}/db.zip", "/var/lib/go-server/db/h2db/")
  restore_files("#{BACKUP_DOWNLOAD_FOLDER}/config-dir.zip", "/etc/go/config/")
  restore_files("#{BACKUP_DOWNLOAD_FOLDER}/config-repo.zip", "/var/lib/go-server/db/config.git/")
  sh %Q{service go-server start}
  wait_to_start("http://localhost:8153/go/pipelines")
end

task :run_test do

end

task :cleanup do

end


task :compute_md5 do
  %w{db.zip config-repo.zip config-dir.zip}.each{|f|
    SNAPSHOT[:MD5].merge!(f.to_sym => Digest::MD5.hexdigest(File.read "#{BACKUP_DOWNLOAD_FOLDER}/#{f}"))
  }
  open("#{BACKUP_DOWNLOAD_FOLDER}/snapshot.json", 'w') do |file|
    file.write(SNAPSHOT.to_json)
  end
end

task :take_db_snapshot do
  rm_rf "#{Dir.tmpdir}/db_check" if Dir.exists?("#{Dir.tmpdir}/db_check")
  mkdir_p "#{Dir.tmpdir}/db_check"
  unzipfile "#{BACKUP_FOLDER}/db.zip","#{Dir.tmpdir}/db_check"
  DB = Sequel.connect("jdbc:h2:file:#{Dir.tmpdir}/db_checkcruise;user=sa;password=''")
  DB["SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='TABLE'"].each{|t|
    table = t[:table_name]
    SNAPSHOT[:TABLES].merge!(table.to_sym => "#{DB[table.to_sym].count}")
  }
  open("#{BACKUP_DOWNLOAD_FOLDER}/snapshot.json", 'a') do |file|
    file.write(SNAPSHOT.to_json)
  end
end


task :restore_test => [:restore, :run_test, :cleanup]
task :post_backup => [:compute_md5, :take_db_snapshot]
