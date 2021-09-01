require 'spec_helper'

describe 'bamboo_agent::private_tmp' do

  let :title do '/footmp' end
  let :params do { 'cleanup_age' => '4d' } end

  let :pre_condition do <<PUPPET
class bamboo_agent {
  $user_name = 'jdoe'
  $user_group = 'jdoe'
}
include bamboo_agent
PUPPET
  end

  it do
    should contain_file('/footmp').with({
      :ensure => 'directory',
      :owner  => 'jdoe',
      :group  => 'jdoe',
      :mode   => '0755',
    })
    should contain_package('tmpreaper')
    should contain_cron('/footmp-tmp-cleanup').with({
      :command => '/usr/sbin/tmpreaper 4d /footmp',
      :minute  => 15,
    })
  end
end
