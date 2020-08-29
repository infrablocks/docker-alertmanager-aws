require 'spec_helper'

describe 'image' do
  image = 'alertmanager-aws:latest'
  extra = {
      'Entrypoint' => '/bin/sh',
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  after(:all, &:reset_docker_backend)

  it 'puts the alertmgr user in the alertmgr group' do
    expect(user('alertmgr'))
        .to(belong_to_primary_group('alertmgr'))
  end

  it 'has the correct ownership on the alertmanager directory' do
    expect(file('/opt/alertmanager')).to(be_owned_by('alertmgr'))
    expect(file('/opt/alertmanager')).to(be_grouped_into('alertmgr'))
  end

  it 'has the correct ownership on the alertmanager data directory' do
    expect(file('/var/opt/alertmanager')).to(be_owned_by('alertmgr'))
    expect(file('/var/opt/alertmanager')).to(be_grouped_into('alertmgr'))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end