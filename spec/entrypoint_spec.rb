# frozen_string_literal: true

require 'spec_helper'

describe 'entrypoint' do
  metadata_service_url = 'http://metadata:1338'
  s3_endpoint_url = 'http://s3:4566'
  s3_bucket_region = 'us-east-1'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
    'AWS_METADATA_SERVICE_URL' => metadata_service_url,
    'AWS_ACCESS_KEY_ID' => '...',
    'AWS_SECRET_ACCESS_KEY' => '...',
    'AWS_S3_ENDPOINT_URL' => s3_endpoint_url,
    'AWS_S3_BUCKET_REGION' => s3_bucket_region,
    'AWS_S3_ENV_FILE_OBJECT_PATH' => s3_env_file_object_path
  }
  image = 'alertmanager-aws:latest'
  extra = {
    'Entrypoint' => '/bin/sh',
    'HostConfig' => {
      'NetworkMode' => 'docker_alertmanager_aws_test_default'
    }
  }

  before(:all) do
    set :backend, :docker
    set :env, environment
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  describe 'by default' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path
      )

      execute_docker_entrypoint(
        started_indicator: 'Listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'runs alertmanager' do
      expect(process('/opt/alertmanager/bin/alertmanager')).to(be_running)
    end

    it 'uses the default configuration' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(%r{--config\.file=/opt/alertmanager/conf/alertmanager.yml}))
    end

    it 'uses a storage path of /var/opt/alertmanager' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(%r{--storage\.path=/var/opt/alertmanager}))
    end

    it 'uses a data retention of 120h' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--data\.retention=120h/))
    end

    it 'uses an alerts GC interval of 30m' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--alerts\.gc-interval=30m/))
    end

    it 'has no external URL' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .not_to(match(/--web\.external-address/))
    end

    it 'has no web route prefix' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .not_to(match(/--web\.route-prefix/))
    end

    it 'has no web get concurrency' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .not_to(match(/--web\.get-concurrency/))
    end

    it 'has no web timeout' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .not_to(match(/--web\.timeout/))
    end

    it 'listens on port 9093 on all interfaces' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--web\.listen-address=:9093/))
    end

    it 'enables HA mode' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.listen-address=0\.0\.0\.0:9094/))
    end

    it 'has no cluster advertise address' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .not_to(match(/--cluster\.advertise-address/))
    end

    it 'has no cluster peers' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .not_to(match(/--cluster\.peer=/))
    end

    it 'uses a cluster peer timeout of 15s' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.peer-timeout=15s/))
    end

    it 'uses a cluster gossip interval of 200ms' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.gossip-interval=200ms/))
    end

    it 'uses a cluster pushpull interval of 1m0s' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.pushpull-interval=1m0s/))
    end

    it 'uses a cluster TCP timeout of 10s' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.tcp-timeout=10s/))
    end

    it 'uses a cluster probe timeout of 500ms' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.probe-timeout=500ms/))
    end

    it 'uses a cluster probe interval of 1s' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.probe-interval=1s/))
    end

    it 'uses a cluster settle timeout of 1m0s' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.settle-timeout=1m0s/))
    end

    it 'uses a cluster reconnect interval of 10s' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.reconnect-interval=10s/))
    end

    it 'uses a cluster reconnect timeout of 6h0m0s' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.reconnect-timeout=6h0m0s/))
    end

    it 'logs using JSON' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--log\.format=json/))
    end

    it 'logs at info level' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--log\.level=info/))
    end

    it 'runs with the alertmgr user' do
      expect(process('/opt/alertmanager/bin/alertmanager').user)
        .to(eq('alertmgr'))
    end

    it 'runs with the alertmgr group' do
      expect(process('/opt/alertmanager/bin/alertmanager').group)
        .to(eq('alertmgr'))
    end
  end

  describe 'with storage configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'ALERTMANAGER_STORAGE_PATH' => '/data',
          'ALERTMANAGER_DATA_RETENTION' => '168h'
        }
      )

      execute_command('mkdir /data')

      execute_docker_entrypoint(
        started_indicator: 'Listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided storage path' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(%r{--storage\.path=/data}))
    end

    it 'uses the provided data retention' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--data\.retention=168h/))
    end
  end

  describe 'with alert configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'ALERTMANAGER_ALERTS_GC_INTERVAL' => '45m'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'Listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided alerts GC interval' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--alerts\.gc-interval=45m/))
    end
  end

  describe 'with web configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'ALERTMANAGER_WEB_EXTERNAL_URL' => 'https://am1.example.com',
          'ALERTMANAGER_WEB_ROUTE_PREFIX' => '/api',
          'ALERTMANAGER_WEB_LISTEN_ADDRESS' => ':9000',
          'ALERTMANAGER_WEB_GET_CONCURRENCY' => '4',
          'ALERTMANAGER_WEB_TIMEOUT' => '10s'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'Listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided web external URL' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(%r{--web\.external-url=https://am1.example.com}))
    end

    it 'uses the provided web route prefix' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(%r{--web\.route-prefix=/api}))
    end

    it 'uses the provided web listen address' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--web\.listen-address=:9000/))
    end

    it 'uses the provided web get concurrency' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--web\.get-concurrency=4/))
    end

    it 'uses the provided web timeout' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--web\.timeout=10s/))
    end
  end

  describe 'with cluster configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'ALERTMANAGER_CLUSTER_LISTEN_ADDRESS' => '0.0.0.0:9095',
          'ALERTMANAGER_CLUSTER_ADVERTISE_ADDRESS' => '10.0.0.1:9095',
          'ALERTMANAGER_CLUSTER_PEERS' =>
            'am1.example.com:9095,am2.example.com:9095',
          'ALERTMANAGER_CLUSTER_PEER_TIMEOUT' => '30s',
          'ALERTMANAGER_CLUSTER_GOSSIP_INTERVAL' => '100ms',
          'ALERTMANAGER_CLUSTER_PUSHPULL_INTERVAL' => '1m30s',
          'ALERTMANAGER_CLUSTER_TCP_TIMEOUT' => '20s',
          'ALERTMANAGER_CLUSTER_PROBE_TIMEOUT' => '800ms',
          'ALERTMANAGER_CLUSTER_PROBE_INTERVAL' => '2s',
          'ALERTMANAGER_CLUSTER_SETTLE_TIMEOUT' => '2m0s',
          'ALERTMANAGER_CLUSTER_RECONNECT_INTERVAL' => '15s',
          'ALERTMANAGER_CLUSTER_RECONNECT_TIMEOUT' => '5h0m0s'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'Listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'listens on the correct cluster address' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.listen-address=0\.0\.0\.0:9095/))
    end

    it 'uses the provided advertise address' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.advertise-address=10\.0\.0\.1:9095/))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'has cluster peers for each provided peer' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.peer=am1.example.com/))
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.peer=am2.example.com/))
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'uses the provided cluster peer timeout' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.peer-timeout=30s/))
    end

    it 'uses the provided cluster gossip interval' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.gossip-interval=100ms/))
    end

    it 'uses the provided pushpull gossip interval' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.pushpull-interval=1m30s/))
    end

    it 'uses the provided cluster TCP timeout' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.tcp-timeout=20s/))
    end

    it 'uses the provided cluster probe timeout' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.probe-timeout=800ms/))
    end

    it 'uses the provided cluster probe interval' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.probe-interval=2s/))
    end

    it 'uses the provided cluster settle timeout' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.settle-timeout=2m0s/))
    end

    it 'uses the provided cluster reconnect interval' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.reconnect-interval=15s/))
    end

    it 'uses the provided cluster reconnect timeout' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--cluster\.reconnect-timeout=5h0m0s/))
    end
  end

  describe 'with logging configuration' do
    before(:all) do
      create_env_file(
        endpoint_url: s3_endpoint_url,
        region: s3_bucket_region,
        bucket_path: s3_bucket_path,
        object_path: s3_env_file_object_path,
        env: {
          'ALERTMANAGER_LOG_LEVEL' => 'debug',
          'ALERTMANAGER_LOG_FORMAT' => 'logfmt'
        }
      )

      execute_docker_entrypoint(
        started_indicator: 'Listening'
      )
    end

    after(:all, &:reset_docker_backend)

    it 'logs using the provided format' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--log\.format=logfmt/))
    end

    it 'logs at the provided level' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
        .to(match(/--log\.level=debug/))
    end
  end

  describe 'configuration' do
    describe 'without configuration object path provided' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path
        )

        execute_docker_entrypoint(
          started_indicator: 'Listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'uses the default configuration' do
        alertmanager_config =
          file('/opt/alertmanager/conf/alertmanager.yml').content

        expect(alertmanager_config)
          .to(eq(File.read('spec/fixtures/default-alertmanager-config.yml')))
      end
    end

    describe 'with configuration object path provided' do
      before(:all) do
        configuration_file_object_path = "#{s3_bucket_path}/alertmanager.yml"

        create_object(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: configuration_file_object_path,
          content: File.read('spec/fixtures/custom-alertmanager-config.yml')
        )
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'ALERTMANAGER_CONFIGURATION_FILE_OBJECT_PATH' =>
              configuration_file_object_path
          }
        )

        execute_docker_entrypoint(
          started_indicator: 'Listening'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'uses the provided configuration' do
        alertmanager_config =
          file('/opt/alertmanager/conf/alertmanager.yml').content

        expect(alertmanager_config)
          .to(eq(File.read('spec/fixtures/custom-alertmanager-config.yml')))
      end
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end

  def create_env_file(opts)
    create_object(opts
                    .merge(content: (opts[:env] || {})
                      .to_a
                      .collect { |item| " #{item[0]}=\"#{item[1]}\"" }
                      .join("\n")))
  end

  def execute_command(command_string)
    command = command(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise "\"#{command_string}\" failed with exit code: #{exit_status}"
    end

    command
  end

  def create_object(opts)
    make_bucket(opts)
    copy_content(opts)
  end

  def make_bucket(opts)
    execute_command('aws ' \
                    "--endpoint-url #{opts[:endpoint_url]} " \
                    's3 ' \
                    'mb ' \
                    "#{opts[:bucket_path]} " \
                    "--region \"#{opts[:region]}\"")
  end

  def copy_content(opts)
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " \
                    'aws ' \
                    "--endpoint-url #{opts[:endpoint_url]} " \
                    's3 ' \
                    'cp ' \
                    '- ' \
                    "#{opts[:object_path]} " \
                    "--region \"#{opts[:region]}\" " \
                    '--sse AES256')
  end

  def execute_docker_entrypoint(opts)
    logfile_path = '/tmp/docker-entrypoint.log'
    started_indicator = opts[:started_indicator]

    trigger_docker_entrypoint_in_background(logfile_path)
    wait_for_started_indicator_to_be_present(logfile_path, started_indicator)
  end

  def trigger_docker_entrypoint_in_background(logfile_path)
    execute_command(
      "docker-entrypoint.sh > #{logfile_path} 2>&1 &"
    )
  end

  def wait_for_started_indicator_to_be_present(logfile_path, started_indicator)
    Octopoller.poll(timeout: 5) do
      should_re_poll?(logfile_path, started_indicator)
    end
  rescue Octopoller::TimeoutError => e
    puts read_path(logfile_path)
    raise e
  end

  def should_re_poll?(logfile_path, started_indicator)
    logfile_contents = read_path(logfile_path)
    if logfile_contents =~ /#{started_indicator}/
      logfile_contents
    else
      :re_poll
    end
  end

  def read_path(logfile_path)
    command("cat #{logfile_path}").stdout
  end
end
