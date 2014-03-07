# -*- encoding : utf-8 -*-
# Fog.credentials_path = Rails.root.join("config/aws.yml")

CarrierWave.configure do |config|
  aws = YAML.load_file("config/aws.yml")[Rails.env]
  config.storage    = :aws
  config.aws_bucket = aws[:s3_bucket_name]
  config.aws_acl    = :public_read_write
  config.asset_host = aws[:s3_host_name] 

  config.aws_credentials = {
    :provider               => 'AWS',                     # required
    :aws_access_key_id      => aws[:access_key_id],       # required
    :aws_secret_access_key  => aws[:secret_access_key],   # required
    :region                 => aws[:s3_region]
  }
end
