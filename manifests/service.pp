# Declares the agent a Puppet service and ensures it is running and enabled,
# after rendering an init script that delegates to the agent's bamboo-agent.sh
# script.
# *** This type should be considered private to this module ***
define bamboo_agent::service(
  $home,
  $id = $title,
){

  $service = "bamboo-agent${id}"
  $script  = "${home}/bin/bamboo-agent.sh"
  $user    = $::bamboo_agent::user_name

  if $facts['os']['release']['major'] == '7' {
    $service_script  = "/etc/systemd/system/${service}.service"
    $script_template = template('bamboo_agent/systemd-service.erb')
    $mode = '0664'
    file {
      "/etc/systemd/system/${service}.d":
        ensure => directory,
      ;
      "/etc/systemd/system/${service}.d/environment.conf":
        ensure => file,
        source => 'puppet:///modules/bamboo_agent/environment.conf',
      ;
    }
  } else {
    $service_script  = "/etc/init.d/${service}"
    $script_template = template('bamboo_agent/init-script.erb')
    $mode = '0755'
  }

  file { $service_script:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => $mode,
    content => $script_template,
  }
  ->
  service { $service:
    ensure    => running,
    enable    => true,
  }
}
