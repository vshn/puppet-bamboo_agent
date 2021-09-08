# Configures a single agent on the node.
#
# === Parameters
#
# [id] A unique-to-this-node name for this agent. Eg: "1","A","jimmy"
#
# [home] Path to agent's home directory (will be created)
#
# [wrapper_conf_properties] List of properties that should be
#   overridden in the agent's wrapper.conf with Augeas.
#
# [manage_capabilities] Whether to manage this agent's capabilities
#   using the bamboo-capabilities.properties file (search the Bamboo
#   docs for "bamboo-capabilities.properties" for information about
#   configuring agents this way)
#
# [capabilities] Hash of capabilities to set for this agent. Only
#   applies if $manage_capabilities is true.
#
# [expand_id_macros] When true, any occurrences of the string "!ID!"
#   in the capabilities hash will be replaced with $id
#
# [private_tmp_dir] Whether to configure this agent to use a private
#   tmp directory, instead of the system tmp directory. 
#
# [private_tmp_cleanup_age] Maximum age of files in tmp dir that should
#   be cleaned up with tmpreaper. Eg. "10d", "1d", "4h"
#
# [refresh_service] Whether to restart the agent after a change to
#   bamboo-capabilities.properties or wrapper.conf.
#
# [description] The description of the agent to place into the
# bamboo-agent.cfg.xml file. Defaults to the id of the agent.
#
# === Examples
#
# Suppose an agent on the node "somehost" is defined with the
# following capabilities:
#
# bamboo_agent::agent { '1':
#   ...
#   manage_capabilities => true,
#   capabilities => {
#     'agentkey' => "${::hostname}-!ID!",
#   },
#   expand_id_macros => true,
#   description => 'Bamboo Remote Agent',
# }
#
# The agent would have the custom capability "agentkey" set to
# "somehost-1".
#
define bamboo_agent::agent(
  $build_directory         = "${bamboo_agent::build_directory}",
  $capabilities            = {},
  $description             = $title,
  $expand_id_macros        = true,
  $home                    = "${bamboo_agent::install_dir}/agent${title}-home",
  $id                      = $title,
  $manage_capabilities     = false,
  $private_tmp_dir         = false,
  $private_tmp_cleanup_age = '10d',
  $refresh_service         = false,
  $wrapper_conf_properties = {},
){

  validate_hash($wrapper_conf_properties)
  validate_hash($capabilities)

  if $id !~ /\A[-\w]+\z/ {
    fail("${id} is not a valid agent id")
  }

  file { $home:
    ensure => directory,
    owner  => $bamboo_agent::user_name,
    group  => $bamboo_agent::user_group,
    mode   => '0755',
  }
  ->
  bamboo_agent::install { "install-agent-${id}":
    id     => $id,
    home   => $home,
  }

  $install = Bamboo_Agent::Install["install-agent-${id}"]

  bamboo_agent::service { $id:
    home    => $home,
    require => $install,
  }

  if $manage_capabilities {
    bamboo_agent::capabilities { $id:
      home             => $home,
      capabilities     => merge($bamboo_agent::default_capabilities,
                                $capabilities),
      expand_id_macros => $expand_id_macros,
      before           => Bamboo_Agent::Service[$id],
      require          => $install,
    }

    if $refresh_service {
       Bamboo_Agent::Capabilities[$id] ~> Bamboo_Agent::Service[$id]
    }
  }


  # Bamboo agents now have a $home/temp/log_spool directory that
  # fills everything up, so here's a quick hack to clean things
#  unless defined(Package['tmpreaper']){
#    package { 'tmpreaper': ensure => installed }
#  }
#  $agent_temp = "${home}/temp"
#  cron { "${agent_temp}-cleanup":
#    minute  => '*/15',
#    command => "/usr/sbin/tmpreaper 1h ${agent_temp}",
#    require => Package['tmpreaper'],
#  }


 # if $private_tmp_dir {
 #  $agent_tmp    = "${home}/.agent_tmp"
 # $tmp_dir_props = {
 #  'set.TMP'                   => $agent_tmp,
 #     'wrapper.java.additional.3' => "-Djava.io.tmpdir=${agent_tmp}",
 #   }
 #  bamboo_agent::private_tmp { $agent_tmp:
 #     require => $install,
 #     cleanup_age => $private_tmp_cleanup_age,
 #   }
 # }else{
 #   $tmp_dir_props = {}
 # }

  bamboo_agent::wrapper_conf { $id:
    home       => $home,
    properties => merge($tmp_dir_props,
                        $wrapper_conf_properties),
    before     => Bamboo_Agent::Service[$id],
    require    => $install,
  }

  if $build_directory == '' {
    bamboo_agent::agent_cfg {
      $id:
        home        => $home,
        agent_name  => "${hostname}-${id}",
        description => $description,
        require     => $install,
        notify      => Bamboo_Agent::Service[$id],
    }
  } else {
    bamboo_agent::agent_cfg {
      $id:
        home        => $build_directory,
        agent_name  => "${hostname}-${id}",
        description => $description,
        require     => $install,
        notify      => Bamboo_Agent::Service[$id],
    }
  }

  if $refresh_service {
    Bamboo_Agent::Wrapper_Conf[$id] ~> Bamboo_Agent::Service[$id]
  }
}
