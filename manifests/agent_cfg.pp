# Set name and description within the bamboo agent
# configuration file.
# *** This type should be considered private to this module ***
define bamboo_agent::agent_cfg(
  $home         = $title,
  $description  = $description ,
){

  $path = "${home}/bamboo-agent.cfg.xml"

  file { $path:
    owner => $bamboo_agent::user_name,
    group => $bamboo_agent::user_group,
  } ->
  file_line { "Update name field $path":
    path    => $path,
    line    => "<name>$title</name>",
    match   => "^<name>.*?$"
  } ->
  file_line { "Update description field $path":
    path    => $path,
    line    => "<description>$description</description>",
    match   => "^<description>.*?$"
  }
}
