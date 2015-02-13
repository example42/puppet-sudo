# = Define: sudo::directive
#
# This defines places a directive for the sudoers file
# On old versions of sudo ( < 1.7.2 ) it places a line in
# /etc/sudoers (The Concat module is required for it)
# On more recent versions it just places a file in /etc/sudoers.d
#
# == Parameters
#
# [*content*]
#   Sets the value of content parameter for the sudo fragment.
#   Can be set as an array (joined with newlines)
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
  $order   = '20'
) {

  include sudo

  # sudo skipping file names that contain a "."
  $dname = regsubst($name, '\.', '-', 'G')

  $manage_source = $source ? {
    ''        => undef,
    default   => $source,
  }

  # add a line break at the end, as missing that can make the file invalid
  $manage_content = $content ? {
    ''        => undef,
    default   => inline_template('<%= [@content].flatten.join("\n") + "\n" %>'),
  }

  $manage_syntax_check = $ensure ? {
    'present' => Exec["sudo-syntax-check for file ${dname}"],
    default   => undef,
  }


  if $sudo::config_dir and $sudo::config_dir != '' {
    $base_name = "${sudo::config_dir}/${order}_${dname}"
    file {
      $base_name:
        ensure  => $ensure,
        owner   => $sudo::config_file_owner,
        group   => $sudo::config_file_group,
        mode    => $sudo::config_file_mode,
        content => $manage_content,
        source  => $manage_source,
        notify  => $manage_syntax_check,
        require => Package['sudo'];

      # Remove the .broken file which can be left over by the sudo-syntax-check.
      # This runs intentionally before the syntax-check to leave the file around for debugging.
      "${base_name}.broken":
        ensure => absent,
        before => $manage_syntax_check,
    }

    if $ensure == 'present' {
      exec { "sudo-syntax-check for file ${dname}":
        command     => "visudo -c -f ${base_name} || ( mv -f ${base_name} ${base_name}.broken && exit 1 )",
        refreshonly => true,
        path        => '/bin:/usr/bin:/sbin:/usr/sbin',
      }
    }

  } else {

    concat::fragment { $dname:
      ensure  => $ensure,
      order   => $order,
      target  => $sudo::config_file,
      content => "${manage_content}\n",
      source  => $manage_source,
      require => Package['sudo'],
    }

  }

}
