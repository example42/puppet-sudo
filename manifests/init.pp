# = Class: sudo
#
# This is the main sudo class
#
#
# == Parameters
#
# Standard class parameters
# Define the general class behaviour and customizations
#
# [*my_class*]
#   Name of a custom class to autoload to manage module's customizations
#   If defined, sudo class will automatically "include $my_class"
#   Can be defined also by the (top scope) variable $sudo_myclass
#
# [*source*]
#   Sets the content of source parameter for main configuration file
#   If defined, sudo main config file will have the param: source => $source
#   Can be defined also by the (top scope) variable $sudo_source
#
# [*source_dir*]
#   If defined, the whole sudo configuration directory content is retrieved
#   recursively from the specified source
#   (source => $source_dir , recurse => true)
#   Can be defined also by the (top scope) variable $sudo_source_dir
#
# [*source_dir_purge*]
#   If set to true (default false) the existing configuration directory is
#   mirrored with the content retrieved from source_dir
#   (source => $source_dir , recurse => true , purge => true)
#   Can be defined also by the (top scope) variable $sudo_source_dir_purge
#
# [*template*]
#   Sets the path to the template to use as content for main configuration file
#   If defined, sudo main config file has: content => content("$template")
#   Note source and template parameters are mutually exclusive: don't use both
#   Can be defined also by the (top scope) variable $sudo_template
#
# [*content*]
#   Defines the content of the main configuration file, to be used as alternative
#   to template when the content is populated on other ways.
#   If defined, sudo main config file has: content => $content
#   Note: source, template and content are mutually exclusive.
#   If a template is defined, that has precedence on the content parameter
#
#
# [*options*]
#   An hash of custom options to be used in templates for arbitrary settings.
#   Can be defined also by the (top scope) variable $sudo_options
#
# [*debug*]
#   Set to 'true' to enable modules debugging
#   Can be defined also by the (top scope) variables $sudo_debug and $debug
#
# [*audit_only*]
#   Set to 'true' if you don't intend to override existing configuration files
#   and want to audit the difference between existing files and the ones
#   managed by Puppet.
#   Can be defined also by the (top scope) variables $sudo_audit_only
#   and $audit_only
#
# Default class params - As defined in sudo::params.
# Note that these variables are mostly defined and used in the module itself,
# overriding the default values might not affected all the involved components.
# Set and override them only if you know what you're doing.
# Note also that you can't override/set them via top scope variables.
#
# [*package*]
#   The name of sudo package
#
# [*config_dir*]
#   Configuration directory. Use false to use concat instead.
#
# [*config_file*]
#   Main configuration file path
#
# [*config_file_mode*]
#   Main configuration file path mode
#
# [*config_file_owner*]
#   Main configuration file path owner
#
# [*config_file_group*]
#   Main configuration file path group
#
#
# == Author
#   Alessandro Franceschi <al@lab42.it/>
#
class sudo (
  $my_class            = params_lookup( 'my_class' ),
  $source              = params_lookup( 'source' ),
  $source_dir          = params_lookup( 'source_dir' ),
  $source_dir_purge    = params_lookup( 'source_dir_purge' ),
  $template            = params_lookup( 'template' ),
  $content             = params_lookup( 'content' ),
  $options             = params_lookup( 'options' ),
  $debug               = params_lookup( 'debug' , 'global' ),
  $audit_only          = params_lookup( 'audit_only' , 'global' ),
  $package             = params_lookup( 'package' ),
  $config_dir          = params_lookup( 'config_dir' ),
  $config_file         = params_lookup( 'config_file' ),
  $config_file_mode    = params_lookup( 'config_file_mode' ),
  $config_file_owner   = params_lookup( 'config_file_owner' ),
  $config_file_group   = params_lookup( 'config_file_group' ),
  $version             = params_lookup( 'version' ),
  $directives          = params_lookup( 'directives' )
  ) inherits sudo::params {

  $bool_source_dir_purge=any2bool($source_dir_purge)
  $bool_debug=any2bool($debug)
  $bool_audit_only=any2bool($audit_only)

  $manage_audit = $sudo::bool_audit_only ? {
    true  => 'all',
    false => undef,
  }

  $manage_file_replace = $sudo::bool_audit_only ? {
    true  => false,
    false => true,
  }

  $manage_file_source = $sudo::source ? {
    ''        => undef,
    default   => $sudo::source,
  }

  $manage_file_content = $sudo::template ? {
    ''        => $sudo::content ? {
      ''      => undef,
      default => $sudo::content,
    },
    default   => template($sudo::template),
  }

  # On Solaris, sudo is already part of base install
  # but not registered as a package. Ensuring the package to
  # be absent won't do any harm and makes sure the resource
  # Package['sudo'] is available for dependencies
  $package_ensure = $version ? {
    ''      => $::operatingsystem ? {
      /(?i:Solaris)/ => 'absent',
      default        => 'present',
    },
    default => $version,
  }

  ### Managed resources
  package { 'sudo':
    ensure => $package_ensure,
    name   => $sudo::package,
  }

  if $sudo::config_dir and $sudo::config_dir != '' {
    file { 'sudo.conf':
      ensure  => 'present',
      path    => $sudo::config_file,
      mode    => $sudo::config_file_mode,
      owner   => $sudo::config_file_owner,
      group   => $sudo::config_file_group,
      require => Package['sudo'],
      source  => $sudo::manage_file_source,
      content => $sudo::manage_file_content,
      replace => $sudo::manage_file_replace,
      audit   => $sudo::manage_audit,
    }

    # The whole sudo configuration directory can be recursively overriden
    if $sudo::source_dir and $sudo::source_dir != '' {
      file { 'sudo.dir':
        ensure  => directory,
        path    => $sudo::config_dir,
        require => Package['sudo'],
        source  => $sudo::source_dir,
        recurse => true,
        purge   => $sudo::bool_source_dir_purge,
        replace => $sudo::manage_file_replace,
        audit   => $sudo::manage_audit,
        mode    => $sudo::config_file_mode,
        owner   => $sudo::config_file_owner,
        group   => $sudo::config_file_group,
      }
    }
  } else {

    # Basic /etc/sudoers header for old versions of sudo ( < 1.7.2 )
    concat { $sudo::config_file:
      mode  => $sudo::config_file_mode,
      owner => $sudo::config_file_owner,
      group => $sudo::config_file_group,
    }
    concat::fragment { 'sudoers_head':
      ensure  => present,
      order   => '01',
      target  => $sudo::config_file,
      content => template('sudo/sudoers_head.erb'),
      require => Package['sudo'],
    }

  }

  ### Create instances for integration with Hiera
  if $directives != {} {
    validate_hash($directives)
    create_resources(sudo::directive, $directives)
  }

  ### Include custom class if $my_class is set
  if $sudo::my_class and $sudo::my_class != '' {
    include $sudo::my_class
  }


  ### Debugging, if enabled ( debug => true )
  if $sudo::bool_debug == true {
    file { 'debug_sudo':
      ensure  => present,
      path    => "${settings::vardir}/debug-sudo",
      mode    => '0640',
      owner   => 'root',
      group   => 'root',
      content => inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*|.*psk.*|.*key)/ }.to_yaml %>'),
    }
  }

}
