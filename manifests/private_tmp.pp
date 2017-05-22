# Logic for setting up a private tmp directory for the agent
# *** This type should be considered private to this module ***
define bamboo_agent::private_tmp(
  $path = $title,
  $cleanup_age,
){
  $escaped_age = shellquote($cleanup_age)

  file { $path:
    ensure => directory,
    owner  => $bamboo_agent::user_name,
    group  => $bamboo_agent::user_group,
    mode   => '0755', # Only used by Bamboo user, no need for sticky
  }

  unless defined(Package['tmpwatch']){
    package { 'tmpwatch': ensure => installed }
  }

  cron { "${path}-tmp-cleanup":
    minute  => 15,
    command => "/usr/sbin/tmpwatch ${escaped_age} ${path}",
    require => [Package['tmpwatch'],
                File[$path]],
  }
}
