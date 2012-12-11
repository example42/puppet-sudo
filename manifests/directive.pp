# = Define: sudo::directive
#
# This defines places a directive for the sudoers file
# On old versions of sudo ( < 1.7.2 ) it places a line in
# /etc/sudoers (The Concat module is required for it)
# On more recent versions it just places a file in /etc/sudoers.d
#
# == Parameters
#
# [*source*]
#   Sets the value of source parameter for the sudo fragment
#
# [*template*]
#   Sets the value of content parameter for the sudo fragment
#   Note: This option is alternative to the source one
#
# [*ensure*]
#   Define if the fragment should be present (default) or 'absent'
#
# [*order*]
#   Sets the order of the fragment inside /etc/sudoers or /etc/sudoers.d
#   Default 20
#
define sudo::directive (
  $ensure  = present,
  $content = '',
  $source  = '',
  $order   = '20',
) {

  include sudo

  # sudo skipping file names that contain a "."
  $dname = regsubst($name, '\.', '-', 'G')

  $manage_source = $source ? {
    ''        => undef,
    default   => $source,
  }

  $manage_content = $content ? {
    ''        => undef,
    default   => $content,
  }


  if $sudo::config_dir {

    file { "${sudo::config_dir}/${order}_${dname}":
      ensure  => $ensure,
      owner   => root,
      group   => root,
      mode    => '0440',
      content => $manage_content,
      source  => $manage_source,
      notify  => Exec["sudo-syntax-check for file ${dname}"],
      require => Package['sudo'],
    }

  } else {

    concat::fragment { $dname:
      ensure  => $ensure,
      order   => $order,
      target  => $sudo::config_file,
      content => $manage_content,
      source  => $manage_source,
      require => Package['sudo'],
    }

  }

  exec { "sudo-syntax-check for file ${dname}":
    command     => "visudo -c -f ${sudo::config_dir}/${order}_${dname} || ( rm -f ${sudo::config_dir}/${order}_${dname} && exit 1)",
    refreshonly => true,
    path        => '/bin:/usr/bin:/sbin:/usr/sbin',
  }

}
