# Riofs-cookbook

The purpose of this recipe is to create a s3fs driver for one of your Amazon s3 buckets. 

The cookbook supports using an encrypted data bag to keep data safe in shared situations.

Tested in Amazon Linux 

## Setup

To use, create a data bag per unique riofs configuration. An example is included. Upload using:

    knife data bag from file examples/s3_keys-deploy_key.json

Then, for each node to run this configuration, use a role like this:

    "run_list": [
      "recipe[riofs]",
      ...
    ],
    "override_attributes": [
      "riofs": {
        "data_bag": {
          "name": "s3_keys",
          "item": "deploy_key"
        },
        "user": "ec2-user",
        "group": "ec2-user"
      },
      ...
    }