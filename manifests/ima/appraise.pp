class tpm::ima::appraise(
  String       $package_ensure = $::tpm::package_ensure,
  Boolean      $enable         = true
){

  if $enable {
    # Provides ability to check for special attributes
    package { 'attr':
      ensure => $package_ensure
    }
    # Provides the utility to set the security.ima attributes.
    package { 'ima-evm-utils':
      ensure => $package_ensure
    }

    kernel_parameter { 'ima_appraise_tcb':
      notify   => Reboot_notify['ima_appraise_reboot'],
      bootmode => 'normal'
    }
    # check if ima_apprasal is set on the boot cmdline
    case $facts['cmdline']['ima_appraise'] {
      'fix': {
        # if it is set to fix we need to check if the security.ima attribute extentions
        # have been added to the file system which is done by the fact ima_ext_attr
        case  $facts['ima_ext_attr'] {
          'set': {
            # If the attributes have been set then update the kernel parameter and notify reboot
            kernel_parameter { 'ima_appraise':
              value    => 'enforce',
              bootmode => 'normal',
              notify   => [ Reboot_notify['ima_appraise_enforce_reboot'], Exec['dracut ima appraise rebuild']]
            }
            reboot_notify { 'ima_appraise_enforce_reboot':
              subscribe => Kernel_parameter['ima_appraise']
            }
            exec { 'dracut ima appraise rebuild':
              command     => '/sbin/dracut -f',
              subscribe   => Kernel_parameter['ima_appraise'],
              refreshonly => true
            }

          }
          'not_set': {
            #  If the attributes are not set and the update is not running start the update
            file { '/usr/local/bin/ima_security_attr_update.sh':
              ensure => file,
              owner  => 'root',
              mode   => '0700',
              source => 'puppet:///modules/tpm/ima_security_attr_update.sh'
            }
            exec { 'ima_security_attr_update':
              command => '/usr/local/bin/ima_security_attr_update.sh &',
              unless  => 'grep ima_appraise_reboot `puppet config print vardir`/reboot_notifications.json',
              path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
              require => File['/usr/local/bin/ima_security_attr_update.sh'],
            }
          }
          'updating': {
            # The updates are running so do nothing this run
            notify {'IMA Updates running':
              message  => 'Do not reboot until the the ima_security_attr_update.sh script completes running',
              loglevel => 'warning'
            }
          }
          default: {
            # The status is unknown which means the following file is missing and needs to be
            # recreated.  This shouldn't happen.
            file { '/usr/local/bin/ima_security_attr_update.sh':
              ensure => file,
              owner  => 'root',
              mode   => '0700',
              source => 'puppet:///modules/tpm/ima_security_attr_update.sh'
            }
          }
        }
      }
      'enforce': {
        file { '/usr/local/bin/ima_security_attr_update.sh':
          ensure => absent
        }
      }
      default: {
      # if it is not set or set to off then turn on fix
        kernel_parameter { 'ima_appraise':
          value    => 'fix',
          bootmode => 'normal',
          notify   => Reboot_notify['ima_appraise_fix_reboot']
        }
        file { '/usr/local/bin/ima_security_attr_update.sh':
          ensure => file,
          owner  => 'root',
          mode   => '0700',
          source => 'puppet:///modules/tpm/ima_security_attr_update.sh'
        }
        reboot_notify { 'ima_appraise_fix_reboot':
          subscribe => [
            Kernel_parameter['ima_appraise'],
          ]
        }

      }
    }
  } else {
  # If ima_appraise disabled
    kernel_parameter { ['ima_appraise', 'ima_appraise_tcb']:
      ensure   => absent,
      bootmode => 'normal'
    }
    file { '/usr/local/bin/ima_security_attr_update.sh':
      ensure => absent
    }
  }

  reboot_notify { 'ima_appraise_reboot':
    subscribe => [
      Kernel_parameter['ima_appraise_tcb'],
    ]
  }

}
