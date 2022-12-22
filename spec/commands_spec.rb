# frozen_string_literal: true

require 'spec_helper'

describe 'commands' do
  image = 'alertmanager-aws:latest'
  extra = {
    'Entrypoint' => '/bin/sh'
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  after(:all, &:reset_docker_backend)

  it 'includes the alertmanager command' do
    expect(command('/opt/alertmanager/bin/alertmanager --version').stderr)
      .to(match(/0.24.0/))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end
