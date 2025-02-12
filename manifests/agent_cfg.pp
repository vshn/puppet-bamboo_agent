# Set name and description within the bamboo agent configuration file.
# *** This type should be considered private to this module ***
define bamboo_agent::agent_cfg(
  $agent_name  = $title,
  $description = $description,
  $build_directory,
  $home,
) {
  $config_file = "${home}/bamboo-agent.cfg.xml"
  file {
    $config_file:
      ensure  => file,
      owner   => $bamboo_agent::user_name,
      group   => $bamboo_agent::group_name,
      replace => false,
      content => template('bamboo_agent/bamboo-agent.cfg.xml.erb')
    ;
  }
  augeas {
    "bamboo_agent_config_${agent_name}":
      lens    => 'Xml.lns',
      incl    => $config_file,
      changes => [
        "set configuration/buildWorkingDirectory/#text ${build_directory}/xml-data/build-dir",
        "set configuration/agentDefinition/name/#text ${agent_name}",
        "set configuration/agentDefinition/description/#text ${description}",
      ],
      require => File[$config_file],
    ;
  }
}
