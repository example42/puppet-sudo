# Deprecation notice

This module was designed for Puppet versions 2 and 3. It should work also on Puppet 4 but doesn't use any of its features.

The current Puppet 3 compatible codebase is no longer actively maintained by example42.

Still, Pull Requests that fix bugs or introduce backwards compatible features will be accepted.


# Puppet module: sudo

This is a Puppet module for sudo based on the second generation layout ("NextGen") of Example42 Puppet Modules.

Made by Alessandro Franceschi / Lab42

Based on the sudo module of CamptoCamp: https://github.com/camptocamp/puppet-sudo

Official site: http://www.example42.com

Official git repository: http://github.com/example42/puppet-sudo

Released under the terms of Apache 2 License.

This module requires functions provided by the Example42 Puppi module (you need it even if you don't use and install Puppi)

For detailed info about the logic and usage patterns of Example42 modules check the DOCS directory on Example42 main modules set.

## USAGE 
The configuration of the sudoers file(s) can be done following different approches:
- Manage directly the /etc/sudoers file with the source, template or content arguments
- Manage the whole /etc/sudoers.d/ directory content with the source_dir argument
- Manage single entries in /etc/sudoers.d/ with the sudo::directive define (and eventually the main /etc/sudoers file with custom source/template)
 
* Use custom sources for main config file 

        class { 'sudo':
          source => [ "puppet:///modules/lab42/sudo/sudo.conf-${hostname}" , "puppet:///modules/lab42/sudo/sudo.conf" ], 
        }


* Use custom source directory for the whole configuration dir

        class { 'sudo':
          source_dir       => 'puppet:///modules/lab42/sudo/conf/',
          source_dir_purge => false, # Set to true to purge any existing file not present in $source_dir
        }

* Use custom template for main config file. Note that template and source arguments are alternative. 

        class { 'sudo':
          template => 'example42/sudo/sudo.conf.erb',
        }

* Manage directly the content of the main config file. Note that template has precedence over content.

        class { 'sudo':
          content => inline_template(
            file( "$settings::modulepath/example42/templates/sudo/sudo.conf.erb-${hostname}",
                  "$settings::modulepath/example42/templates/sudo/sudo.conf.erb" ) ),
        }

* Use default sudo class and specific sudo::directive entries

        sudo::directive { 'jenkins':
          content => "jenkins ALL=NOPASSWD: /usr/sbin/puppi \n", # Double quotes and newline (\n) are needed here
        }
        sudo::directive { 'developers':
          content => template('example42/sudo/developers'), # Here is used a template
        }
        sudo::directive { 'joe':
          source => 'puppet:///modules/example42/sudo/sudo-joe', # Here is used a static source
        }

* Automatically include a custom subclass

        class { 'sudo':
          my_class => 'sudo::example42',
        }



[![Build Status](https://travis-ci.org/example42/puppet-sudo.png?branch=master)](https://travis-ci.org/example42/puppet-sudo)
