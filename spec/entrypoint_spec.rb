require 'spec_helper'

describe 'entrypoint' do
  metadata_service_url = 'http://metadata:1338'
  s3_endpoint_url = 'http://s3:4566'
  s3_bucket_region = 'us-east-1'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
      'AWS_METADATA_SERVICE_URL' => metadata_service_url,
      'AWS_ACCESS_KEY_ID' => "...",
      'AWS_SECRET_ACCESS_KEY' => "...",
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
          object_path: s3_env_file_object_path)

      execute_docker_entrypoint(
          started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'runs alertmanager' do
      expect(process('/opt/alertmanager/bin/alertmanager')).to(be_running)
    end

    it 'uses the default configuration' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
          .to(match(/--config\.file=\/opt\/alertmanager\/conf\/alertmanager.yml/))
    end

    it 'logs using JSON' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
          .to(match(/--log\.format=json/))
    end

    it 'logs at info level' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
          .to(match(/--log\.level=info/))
    end

    it 'has no external URL' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
          .not_to(match(/--web\.external-address/))
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

    it 'runs with the alertmgr user' do
      expect(process('/opt/alertmanager/bin/alertmanager').user)
          .to(eq('alertmgr'))
    end

    it 'runs with the alertmgr group' do
      expect(process('/opt/alertmanager/bin/alertmanager').group)
          .to(eq('alertmgr'))
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
              'ALERTMANAGER_CLUSTER_RECONNECT_TIMEOUT' => '5h0m0s',
          })

      execute_docker_entrypoint(
          started_indicator: "Listening")
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

    it 'has cluster peers for each provided peer' do
      expect(process('/opt/alertmanager/bin/alertmanager').args)
          .to(match(/--cluster\.peer=am1.example.com/))
      expect(process('/opt/alertmanager/bin/alertmanager').args)
          .to(match(/--cluster\.peer=am2.example.com/))
    end

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
      raise RuntimeError,
          "\"#{command_string}\" failed with exit code: #{exit_status}"
    end
    command
  end

  def create_object(opts)
    execute_command('aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'mb ' +
        "#{opts[:bucket_path]} " +
        "--region \"#{opts[:region]}\"")
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " +
        'aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'cp ' +
        '- ' +
        "#{opts[:object_path]} " +
        "--region \"#{opts[:region]}\" " +
        '--sse AES256')
  end

  def execute_docker_entrypoint(opts)
    logfile_path = '/tmp/docker-entrypoint.log'

    execute_command(
        "docker-entrypoint.sh > #{logfile_path} 2>&1 &")

    begin
      Octopoller.poll(timeout: 5) do
        docker_entrypoint_log = command("cat #{logfile_path}").stdout
        docker_entrypoint_log =~ /#{opts[:started_indicator]}/ ?
            docker_entrypoint_log :
            :re_poll
      end
    rescue Octopoller::TimeoutError => e
      puts command("cat #{logfile_path}").stdout
      raise e
    end
  end
end
