# Class: sudo::params
#
# This class defines default parameters used by the main module class sudo
# Operating Systems differences in names and paths are addressed here
#
# == Variables
#
# Refer to sudo class for the variables defined here.
#
# == Usage
#
# This class is not intended to be used directly.
# It may be imported or inherited by other classes
#
class sudo::params {

  ### Application related parameters

  $package = $::operatingsystem ? {
    default        => 'sudo',
  }

  # A dedicated config_dir is available from sudo version >= 1.7.2
  $config_dir = $::operatingsystem ? {
    /(?i:Ubuntu)/                   => $::operatingsystemrelease ? {
      '8.04'  => false,
      default => '/etc/sudoers.d',
    },
    /(?i:Debian)/                   => $::operatingsystemrelease ? {
      '4'     => false,
      /^5\./  => false,
      default => '/etc/sudoers.d',
    },
    /(?i:RedHat|Centos|Scientific)/ => $::operatingsystemrelease ? {
      /^4/          => false,
      /^5.[01234]$/ => false,
      default       => '/etc/sudoers.d',
    },
    /(?i:FreeBSD)/                  => '/usr/local/etc/sudoers.d',
    /(?i:XenServer)/                => false,
    default                         => '/etc/sudoers.d',
  }

  $config_file = $::operatingsystem ? {
    /(?i:FreeBSD)/ => '/usr/local/etc/sudoers',
    default        => '/etc/sudoers',
  }

  $config_file_mode = $::operatingsystem ? {
    default => '0440',
  }

  $config_file_owner = $::operatingsystem ? {
    default => 'root',
  }

  $config_file_group = $::operatingsystem ? {
    'FreeBSD' => 'wheel',
    default => 'root',
  }

  # General Settings
  $my_class = ''
  $source = ''
  $source_dir = undef
  $source_dir_purge = false
  $template = ''
  $content = ''
  $options = ''
  $debug = false
  $audit_only = false
  $version = ''
  $directives = {}

}
