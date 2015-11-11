node['riofs']['packages'].each do |pkg|
  package pkg
end

# install libevent
remote_file "#{Chef::Config[:file_cache_path]}/libevent-#{ node['libevent']['version'] }.tar.gz" do
  source "https://github.com/downloads/libevent/libevent/libevent-#{ node['libevent']['version'] }.tar.gz"
  mode 0644
  action :create_if_missing
end

bash "install libevent" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
  tar zxvf libevent-#{node['libevent']['version']}.tar.gz
  cd libevent-#{node['libevent']['version']}
  ./configure
  make
  make install
  EOH

  not_if { File.exists?("/usr/local/lib/libevent.so") }
end

template "/etc/ld.so.conf.d/riofs.conf" do
  source "riofs.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

bash "ldconfig" do
  code <<-EOH
  ldconfig
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
  EOH
end

# install riofs
remote_file "#{Chef::Config[:file_cache_path]}/riofs-#{node['riofs']['version']}.tar.gz" do
  source "https://github.com/skoobe/riofs/archive/v#{node['riofs']['version']}.tar.gz"
  mode 0644
  action :create_if_missing
end

bash "install riofs" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
  tar zxvf riofs-#{node['riofs']['version']}.tar.gz
  cd riofs-#{ node['riofs']['version'] }
  ./autogen.sh
  ./configure 
  make
  make install
  EOH

  not_if { File.exists?("/usr/local/bin/riofs") }
end

def retrieve_s3_bucket(data_bag_item)

  s3_bag = data_bag_item(node['riofs']['data_bag']['name'], data_bag_item)

  if s3_bag['access_key_id'].include? 'encrypted_data'
    s3_bag = Chef::EncryptedDataBagItem.load(node['riofs']['data_bag']['name'], data_bag_item)
  end

  bucket = {
    :name => s3_bag['bucket'],
    :path => File.join(node['riofs']['mount_root'], s3_bag['bucket']),
    :access_key => s3_bag['access_key_id'],
    :secret_key => s3_bag['secret_access_key']
  }

  bucket
end

bucket = retrieve_s3_bucket(node['riofs']['data_bag']['item'])

if node['riofs']['user']
  riofs_user_id = node['etc']['passwd'][node['riofs']['user']]['uid']
else
  riofs_user_id = -1
end

if node['riofs']['group']
  riofs_group_id = node['etc']['group'][node['riofs']['group']]['gid'] 
else
  riofs_group_id = -1
end

template "/usr/local/etc/riofs/riofs.conf.xml" do
  source "riofs.conf.xml.erb"
  owner "root"
  group "root"
  mode 0755
  variables(:bucket => bucket,
            :user_id => riofs_user_id,
            :group_id => riofs_group_id)
end

template "/etc/fuse.conf" do
  source "fuse.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

directory bucket[:path] do
  owner     "ec2-user"
  group     "ec2-user"
  mode      0777
  recursive true
  not_if { File.exists?("#{bucket[:path]}") }
end

bash "clean riofs" do
  cwd Chef::Config[:file_cache_path]
  user "root"
  code <<-EOH
  if pgrep riofs;
  then killall riofs;
  fi
  EOH
end

bash "execute riofs" do
  cwd Chef::Config[:file_cache_path]
  user "ec2-user"
  code <<-EOH
  /usr/local/bin/riofs -o #{node["riofs"]["options"]} #{bucket[:name]} #{bucket[:path]}
  EOH
end