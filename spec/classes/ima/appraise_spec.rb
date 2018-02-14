require 'spec_helper'

shared_examples_for 'an ima appraise enabled system' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_package('attr') }
  it { is_expected.to create_package('ima-evm-utils') }
  it { is_expected.to create_kernel_parameter('ima_appraise_tcb')}
end

describe 'tpm::ima::appraise' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

#      if os_facts[:operatingsystemmajrelease].to_s == '7'

      context 'with enable true' do
        let (:params) {{
          enable: true,
          package_ensure: 'install'
        }}

        context  'with no ima appraise cmdline parameters' do
          let(:facts) do
            os_facts.merge({
             :cmdline      => { 'foo' => 'bar' },
            })
          end

          it_should_behave_like 'an ima appraise enabled system'
          it { is_expected.to contain_kernel_parameter('ima_appraise').with({
            'value'    => 'fix',
            'bootmode' => 'normal',
            'notify'   => 'Reboot_notify[ima_appraise_fix_reboot]'
          })}
          it { is_expected.to contain_file('/usr/local/bin/ima_security_attr_update.sh').with({
            'source' => 'puppet:///modules/tpm/ima_security_attr_update.sh',
            'ensure' => 'file',
            'mode'   => '0700'
          })}
          it { is_expected.to contain_reboot_notify('ima_appraise_fix_reboot').that_subscribes_to('Kernel_parameter[ima_appraise]')}

        end

        context 'with ima_apraise = fix' do
          let(:fix_facts) do
            os_facts.merge({
              :cmdline      => { 'ima_appraise' => 'fix' }
            })
          end

          context 'with fact ima_ext_attr = set' do
            let(:facts) do
              fix_facts.merge({
                :ima_ext_attr => 'set'
              })
            end

            it_should_behave_like 'an ima appraise enabled system'
            it { is_expected.to contain_kernel_parameter('ima_appraise').with({
              'value'    => 'enforce',
              'bootmode' => 'normal',
              'notify'   => 'Reboot_notify[ima_appraise_enforce_reboot]'
            })}
            it { is_expected.to contain_reboot_notify('ima_appraise_enforce_reboot').that_subscribes_to('Kernel_parameter[ima_appraise]')}
          end

          context 'with fact ima_ext_attr = not_set' do
            let(:facts) do
              fix_facts.merge({
                :ima_ext_attr => 'not_set'
              })
            end

            it { is_expected.to create_exec('ima_security_attr_update') }
          end

          context 'with fact ima_ext_attr = updating' do
            let(:facts) do
              fix_facts.merge({
                :ima_ext_attr => 'updating'
              })
              it { is_expected.to contain_notify('IMA Updates running') }
            end

          end

          context 'with fact ima_ext_attr = unknown' do
            let(:facts) do
              fix_facts.merge({
                :ima_ext_attr => 'unknown'
              })
            end
            it { is_expected.to contain_file('/usr/local/bin/ima_security_attr_update.sh').with({
              'source' => 'puppet:///modules/tpm/ima_security_attr_update.sh',
              'ensure' => 'file',
              'mode'   => '0700'
            })}
          end

          context 'with fact ima_ext_attr = junk' do
            let(:facts) do
              fix_facts.merge({
                :ima_ext_attr => 'junk'
              })
            end
            it { is_expected.to contain_file('/usr/local/bin/ima_security_attr_update.sh').with({
              'source' => 'puppet:///modules/tpm/ima_security_attr_update.sh',
              'ensure' => 'file',
              'mode'   => '0700'
            })}
          end

        end

        context 'with ima_appraise = enforce' do
          let(:facts) do
            os_facts.merge({
             :cmdline      => { 'ima_appraise' => 'enforce' },
            })
          end
          it_should_behave_like 'an ima appraise enabled system'
          it { is_expected.to contain_file('/usr/local/bin/ima_security_attr_update.sh').with({
            'ensure' => 'absent',
          })}
        end
      end

      context 'with enable false' do
        let (:params) {{
          enable: false,
          package_ensure: 'install'
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_kernel_parameter('ima_appraise').with_ensure('absent')}
        it { is_expected.to contain_kernel_parameter('ima_appraise_tcb').with_ensure('absent')}
        it { is_expected.to contain_file('/usr/local/bin/ima_security_attr_update.sh').with_ensure('absent')}
      end
    end
  end
end

#            let (:facts)      .with_command('cat /etc/ima/policy.conf > /sys/kernel/security/ima/policy') }
#            it { is_expected.to create_file('/etc/ima/policy.conf') \
#            .with_content(IO.read('spec/files/default_ima_policy.conf')) }
#          if os_facts[:operatingsystemmajrelease].to_s == '6'
#            it { is_expected.to create_file('/etc/init.d/import_ima_rules').with({
#            :ensure => 'file'
#          })}
#          it { is_expected.to create_service('import_ima_rules').with({
#            :ensure  => 'stopped',
#            :enable  => true,
#          }) }
#        else
#          it { is_expected.to create_exec('systemd_load_policy') }
#        end
#      end
#
#      context 'with an selinux policy disabled' do
#        let(:params) {{
#          dont_watch_lastlog_t: false,
#        }}
#        it { is_expected.to compile.with_all_deps }
#        it { is_expected.to create_file('/etc/ima/policy.conf') \
#          .with_content(IO.read('spec/files/selinux_ima_policy.conf')) }
#      end
#
#      context 'with an fsmagic disabled' do
#        let(:params) {{
#          dont_watch_binfmtfs: false,
#        }}
#        it { is_expected.to compile.with_all_deps }
#        it { is_expected.to create_file('/etc/ima/policy.conf') \
#          .with_content(IO.read('spec/files/fsmagic_ima_policy.conf')) }
#      end
#
#      context 'with custom selinux contexts' do
#        let(:params) {{
#          dont_watch_list: [ 'user_home_t', 'locale_t' ],
#        }}
#        it { is_expected.to compile.with_all_deps }
##        it { is_expected.to create_file('/etc/ima/policy.conf') \
#          .with_content(IO.read('spec/files/custom_ima_policy.conf')) }
#      end
#
#      context 'with the other ima params set' do
#        let(:params) {{
#          measure_root_read_files: true,
##          measure_file_mmap: true,
#          measure_bprm_check: true,
#          measure_module_check: true,
##          appraise_fowner: true,
#        }}
#        it { is_expected.to compile.with_all_deps }
#        # it { require 'pry';binding.pry }
#        it { is_expected.to create_file('/etc/ima/policy.conf') \
#          .with_content(IO.read('spec/files/other_ima_policy.conf').chomp) }
#      end
#    end
#  end
##end
