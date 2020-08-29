require 'spec_helper'

describe 'prometheus' do
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
          .not_to(match(/--cluster\.peer/))
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
                  'am1.example.com:9095,am2.example.com:9095'
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
