
default["riofs"]["packages"] = %w{gcc libstdc++-devel gcc-c++ automake curl-devel libxml2-devel openssl-devel mailcap make fuse fuse-devel glib2-devel libevent-devel}
default["riofs"]["mount_root"] = '/srv'
default["riofs"]["version"] = "0.6"
default["riofs"]["options"] = 'allow_other,nonempty'

default["riofs"]["data_bag"]["name"] = "s3_keys"
default["riofs"]["data_bag"]["item"] = "deploy_key"

default["libevent"]["version"] = "2.0.21-stable"
