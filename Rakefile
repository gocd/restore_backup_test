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

require 'digest'
require 'sequel'
require 'java'
require_relative 'lib/helper.rb'

BACKUP_FOLDER = '/mnt/go_server/go-server/artifacts/serverBackups/backup_*/'
BACKUP_DOWNLOAD_FOLDER = './go_server_backup'
BACKUP_SERVER_URL = ENV['BACKUP_SERVER_URL']

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
  db_checksum = Digest::MD5.hexdigest File.read "#{BACKUP_FOLDER}/db.zip"
  config_repo_checksum = Digest::MD5.hexdigest File.read "#{BACKUP_FOLDER}/config-repo.zip"
  config_dir_checksum = Digest::MD5.hexdigest File.read "#{BACKUP_FOLDER}/config-dir.zip"
  open("#{BACKUP_FOLDER}/version.txt", 'a') do |file|
    file.puts "db.zip MD5: #{db_checksum}"
    file.puts "config-repo.zip MD5: #{config_repo_checksum}"
    file.puts "config-dir.zip MD5: #{config_dir_checksum}"
  end
end

task :take_db_snapshot do
  rm_rf "#{Dir.tmpdir}/db_check" if Dir.exists?("#{Dir.tmpdir}/db_check")
  mkdir_p "#{Dir.tmpdir}/db_check"
  unzipfile zip_file,"#{Dir.tmpdir}/db_check"

end


task :default => [:restore, :run_test, :cleanup]
