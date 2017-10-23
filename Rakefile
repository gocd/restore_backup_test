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
require 'aws-sdk-s3'

include Test::Unit::Assertions

BACKUP_FOLDER = ENV['BACKUP_FOLDER'] || '/mnt/go_server/go-server/artifacts/serverBackups'
BACKUP_DOWNLOAD_FOLDER = ENV['BACKUP_DOWNLOAD_FOLDER'] ||  './go_server_backup'
BACKUP_SERVER_URL = ENV['BACKUP_SERVER_URL']
POSTGRES_BACKUP = ENV['POSTGRES_BACKUP'] || 'NO'
SNAPSHOT = {:MD5 => {},:TABLES => {}}
PG_DB_NAME = ENV['PG_DB_NAME'] || "cruise"
PG_USER_NAME = ENV['PG_USER_NAME'] || "cruise"


class Redhat
  include Rake::DSL if defined?(Rake::DSL)

  def repo
    open('/etc/yum.repos.d/gocd.repo', 'w') do |f|
      f.puts('[gocd]')
      f.puts('name=gocd')
      f.puts('baseurl=https://download.gocd.io')
      f.puts('enabled=1')
      f.puts('gpgcheck=1')
      f.puts('gpgkey=https://download.gocd.io/GOCD-GPG-KEY.asc')
      f.puts('[gocd-exp]')
      f.puts('name=gocd-exp')
      f.puts('baseurl=https://download.gocd.io/experimental')
      f.puts('enabled=1')
      f.puts('gpgcheck=1')
      f.puts('gpgkey=https://download.gocd.io/GOCD-GPG-KEY.asc')
    end
    sh("yum makecache --disablerepo='*' --enablerepo='gocd*'")
  end

  def install(pkg)
    sh("sudo yum install --assumeyes #{pkg}")
  end

  def uninstall(pkg)
    sh("sudo yum remove --assumeyes #{pkg}")
  end

  def setup_postgres()
    sh(%Q{sudo -u postgres dropdb #{PG_DB_NAME} || true})
    sh(%Q{sudo -u postgres dropuser --if-exists #{PG_USER_NAME}})
    sh(%Q{sudo -u postgres createuser -s #{PG_USER_NAME}})
    sh(%Q{sudo -H -u postgres bash -c 'createdb -U postgres #{PG_DB_NAME}'})
  end
end

task :restore_files do
  %w{*.zip *.sqlc}.each{|file_type|
    snapshot = JSON.parse(File.read("#{BACKUP_DOWNLOAD_FOLDER}/snapshot.json"))
    Dir["#{BACKUP_DOWNLOAD_FOLDER}/**/#{file_type}"].each {|f|
      filename = f.split("/").last
      assert snapshot["MD5"][filename] == Digest::MD5.hexdigest(File.read "#{BACKUP_DOWNLOAD_FOLDER}/#{filename}")
      p "Backup files Snapshot validation successful for file #{f}"
    }
  }

  Redhat.new.install("go-server-#{server_version}")
  mkdir_p "/var/lib/go-server/db/config.git"
  {"config-dir.zip" => "/etc/go/","config-repo.zip" => "/var/lib/go-server/db/config.git/"}.each do |file, dest|
    restore_files("#{BACKUP_DOWNLOAD_FOLDER}/#{file}", dest)
  end

  mkdir_p "/var/lib/go-server/weblogs"

end

task :restore_h2 do

  restore_files("#{BACKUP_DOWNLOAD_FOLDER}/db.zip",  "/var/lib/go-server/db/h2db/")

  DB_CONN = Sequel.connect("jdbc:h2:file:/var/lib/go-server/db/h2db/cruise;user=sa")
  DB_CONN["SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='TABLE'"].each{|t|
    table = t[:table_name]
    snapshot = JSON.parse(File.read("#{BACKUP_DOWNLOAD_FOLDER}/snapshot.json"))
    assert snapshot["TABLES"][table] == DB_CONN[table.to_sym].count.to_s
    p "DB Snapshot validation successful for table #{table}"
  }

end

task :restore_pg do

  mkdir_p "/var/lib/go-server/addons"
  json = JSON.parse(File.read("../addons_compatability_map/addon_builds.json"))
  addon = json.select{|v| v['gocd_version'] == "#{server_version}"}.last['addons']['postgresql']
  sh "curl -L -o /var/lib/go-server/addons/#{addon} --fail -H 'Accept: binary/octet-stream' --user '#{ENV['EXTENSIONS_USER']}:#{ENV['EXTENSIONS_PASSWORD']}'  #{ENV['ADDON_DOWNLOAD_URL']}/#{server_version}/download?eula_accepted=true"
  sh("mv /etc/go/postgresqldb.properties /etc/go/postgresqldb.properties.bkp")

  sh(%Q{sudo -H -u go bash -c 'echo "db.host=localhost"  >> /etc/go/postgresqldb.properties'})
  sh(%Q{sudo -H -u go bash -c 'echo "db.port=5432"  >> /etc/go/postgresqldb.properties'})
  sh(%Q{sudo -H -u go bash -c 'echo "db.name=#{PG_DB_NAME}"  >> /etc/go/postgresqldb.properties'})
  sh(%Q{sudo -H -u go bash -c 'echo "db.user=postgres"  >> /etc/go/postgresqldb.properties'})
  sh(%Q{sudo -H -u go bash -c 'echo "db.password=postgres"  >> /etc/go/postgresqldb.properties'})

end

task :start_server do
  mkdir_p "/var/lib/go-server/weblogs"
  sh "sudo chmod 664 /etc/default/go-server"
  open('/etc/default/go-server', 'a') do |f|
    f.puts('SERVER_MAX_MEM=8g')
    f.puts('SERVER_MEM=1024m')
  end
  # p "Replace server.sh with one in GOCD version 17.10.0"
  sh("sudo cp -r --remove-destination lib/server.sh /usr/share/go-server/server.sh")
  sh("sudo chmod 777 /usr/share/go-server/server.sh")
  sh("sudo ls -l /usr/share/go-server/server.sh")
  p "Server start initiating....."
  sh "service go-server start"
end

task :run_test do
  p "Starting to run test..."
  wait_to_start("http://localhost:8153/go/pipelines")
end

task :cleanup do
  Redhat.new.uninstall("go-server-#{server_version}")
  rm_rf "/var/lib/go-server"
  rm_rf "/var/log/go-server"
  rm_rf "/etc/go"
end

task :snapshot_files do
  %w(*.zip *.sqlc).each{|file_type|
    Dir["#{BACKUP_DOWNLOAD_FOLDER}/**/#{file_type}"].each {|f| SNAPSHOT[:MD5].merge!(f.split('/').last.to_sym => Digest::MD5.hexdigest(File.read "#{f}"))}
  }

  open("#{BACKUP_DOWNLOAD_FOLDER}/snapshot.json", 'w') do |file|
    file.write(SNAPSHOT.to_json)
  end
end

task :snapshot_h2 do

  clean_create_dir("#{Dir.tmpdir}/db")
  dbfile = Dir["#{BACKUP_DOWNLOAD_FOLDER}/**/db.zip"].first.to_s
  unzipfile dbfile,"#{Dir.tmpdir}/db"
  DB = Sequel.connect("jdbc:h2:file:#{Dir.tmpdir}/db/cruise;user=sa")
  DB["SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='TABLE'"].each{|t|
    table = t[:table_name]
    SNAPSHOT[:TABLES].merge!(table.to_sym => "#{DB[table.to_sym].count}")
  }

  open("#{BACKUP_DOWNLOAD_FOLDER}/snapshot.json", 'w') do |file|
    file.write(SNAPSHOT.to_json)
  end
end

task :snapshot_pg do

  Redhat.new.setup_postgres()
  dbfile = Dir["#{BACKUP_DOWNLOAD_FOLDER}/**/*.sqlc"].first.to_s
  sh(%Q{sudo -H -u postgres pg_restore -U postgres --dbname=#{PG_DB_NAME} < "#{dbfile}"})
  #DB = Sequel.connect("postgres://postgres:postgres@localhost:5432/#{PG_DB_NAME}")
  #DB["SELECT table_name FROM information_schema.tables WHERE table_schema='public'"].each{|t|
  #  SNAPSHOT[:TABLES].merge!(t.to_sym => "#{DB[t.to_sym].count}")
  #}

  #open("#{BACKUP_DOWNLOAD_FOLDER}/snapshot.json", 'w') do |file|
  #  file.write(SNAPSHOT.to_json)
  #end
end

task :fetch_backup do
  clean_create_dir(BACKUP_DOWNLOAD_FOLDER)
  backup_location_info = File.read("backup_location_info")
  sh %Q{wget -r -nH -nd -np -R "index.html*" #{BACKUP_SERVER_URL}#{backup_location_info}/ -P #{BACKUP_DOWNLOAD_FOLDER}/}
end

task :fetch_backup_from_s3 do
  clean_create_dir(BACKUP_DOWNLOAD_FOLDER)
  aes_filename = File.read("aes_filename")
  Aws.config.update({
    region: 'us-west-2',
    credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  })
  s3 = Aws::S3::Client.new
  s3.get_object({ bucket:ENV['S3_BUCKET'], key:aes_filename.chop }, target: "#{BACKUP_DOWNLOAD_FOLDER}/backup.tar.gz.aes")
  cd "#{BACKUP_DOWNLOAD_FOLDER}" do
    sh("aes -d -p #{ENV['AES_PASSWORD']} backup.tar.gz.aes")
    sh("tar -xvf *.tar.gz")
  end
end

task :h2_restore_test => [:fetch_backup, :snapshot_files, :snapshot_h2, :restore_files, :restore_h2, :start_server, :run_test, :cleanup]
task :pg_restore_test => [:fetch_backup, :snapshot_files, :snapshot_pg, :restore_files, :restore_pg, :start_server, :run_test, :cleanup]
task :h2_restore_from_s3_test => [:fetch_backup_from_s3, :snapshot_files, :snapshot_h2, :restore_files, :restore_h2, :start_server, :run_test, :cleanup]
